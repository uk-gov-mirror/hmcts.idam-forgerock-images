#!/usr/bin/env bash

FR_VERSION=6.5.2

# ======================================================================================================================
# ======================================================================================================================
function printStepTitle() {
  echo -e "\n==> $1\n"
}

function printHeader() {
  cat <<EOF
====================================
FORGEROCK K8S IMAGES BUILDING SCRIPT
====================================
EOF
}

function checkDependency() {
  printf -- "- %-15s" "$1"
  [ -x "$(command -v "$1")" ] || { printf -- "not found!\n" && exit 1; }
  printf -- "ok\n"
}

function checkDependencies() {
  echo "Checking required dependencies..."
  checkDependency git
  checkDependency docker
  checkDependency kubectl
  checkDependency helm
  [ "$(helm version | grep -c v2)" -gt "0" ] || {
    echo "Helm version 2 is required. Version 3 is not supported."
    exit 1
  }
  checkDependency kubectx
  checkDependency stern
  checkDependency minikube
  checkDependency kubens
  checkDependency VirtualBox
}

function requireEnvVariable() {
  [ -z "${!1}" ] && { echo "This operation requires the \"$1\" variable which was not found (or was empty)!" && exit 1; }
  echo "Found \$${1}."
}

function printUsage() {
  local ptrn="  %-20s\t%s\n"
  printf "Usage: %s command\n" "$(basename $0)"
  printf "Where command is one of:\n"
  printf "$ptrn" "build-downloader" "Builds a base downloader Docker Image, required for building all other images."
  printf "$ptrn" "build-fr-all" "Builds all required ForgeRock Docker Images, required a Downloader image as a base image."
  printf "$ptrn" "configure" "Configures local Kubernetes for ForgeRock deployment."
  printf "$ptrn" "deploy" "Deploys ForgeRock locally using Minikube. All images need to be built beforehand."
  printf "$ptrn" "redeploy" "Redeploys ForgeRock locally using Minikube. Combines undeploy, configure and deploy."
  printf "$ptrn" "undeploy" "Undeploys ForgeRock locally using Minikube."
}

function switchToK8sDockerRegistry() {
  printStepTitle "Switching to the internal Minikube Docker registry..."
  eval "$(minikube -p minikube docker-env --shell bash)" || exit 1
  echo "OK"
}

function buildFRDownloader() {
  printStepTitle "Building the ForgeRock downloader Docker Image.."
  requireEnvVariable "FR_API_KEY"

  checkDependencies
  startMinikube
  switchToK8sDockerRegistry

  docker build --build-arg API_KEY="$FR_API_KEY" --tag forgerock/downloader -f forgeops/docker/downloader/Dockerfile forgeops/docker/downloader || exit 1
}

function buildAndPushDockerImage() {
  printStepTitle "Building $1 Docker Image.."

  docker build --tag forgerock/$1:$FR_VERSION -f forgeops/docker/$1/Dockerfile forgeops/docker/$1 || exit 1
}

function buildFRAppsImages() {
  printStepTitle "Building all the ForgeRock Docker Images..."

  checkDependencies
  startMinikube
  switchToK8sDockerRegistry

  buildAndPushDockerImage openam
  buildAndPushDockerImage openidm
  buildAndPushDockerImage ds
  buildAndPushDockerImage amster
}

function startMinikube() {
  printStepTitle "Starting a Minikube cluster.."
  if [ "$(minikube status | grep -c "Stopped\|Nonexistent")" = "0" ]; then
    echo "Minikube already running."
  else
    minikube start --memory=8192 --disk-size=30g --vm-driver=virtualbox --bootstrapper kubeadm --kubernetes-version=v1.15.0 || exit 1
  fi
}

function configure() {
  printStepTitle "Configuring local Kubernetes..."

  requireEnvVariable CONFIG_REPO_PRIVATE_KEY_PATH
  checkDependencies
  startMinikube
  switchToK8sDockerRegistry

  printStepTitle "Setting up Helm on Minikube..."
  if [ -z "$(kubectl get pods --all-namespaces | grep tiller-deploy)" ]; then
    helm init --upgrade --service-account default || exit 1
    echo "Sleeping to give Tiller time to start.."
    sleep 15
  else
    echo "Already set up."
  fi

  printStepTitle "Enabling Minikube Ingress Controller..."
  minikube addons enable ingress || exit 1

  printStepTitle "Installing the Certificate Manager..."
  if [ -z "$(kubectl get customresourcedefinitions | grep certmanager)" ]; then
    helm install stable/cert-manager --namespace kube-system --version v0.5.0 || exit 1
  else
    echo "Already installed."
  fi

  printStepTitle "Creating a Kubernetes namespace..."
  if [ -z "$(kubectl get namespaces | grep forgerock-local)" ]; then
    kubectl create namespace forgerock-local || exit 1
  else
    echo "Namespace already exists."
  fi

  printStepTitle "Switching namespaces..."
  kubens forgerock-local || exit 1

  printStepTitle "Copying the Configuration Repository Private Key..."
  if [ -f "$CONFIG_REPO_PRIVATE_KEY_PATH" ]; then
    echo "Copying:"
    cp -v "$CONFIG_REPO_PRIVATE_KEY_PATH" forgeops/helm/frconfig/secrets/id_rsa || exit 1
  else
    echo "File not found: $CONFIG_REPO_PRIVATE_KEY_PATH"
    exit 1
  fi

  printStepTitle "Installing frconfig Helm Chart..."
  if [ ! -z "$(helm list --all | grep frconfig)" ]; then
    echo "Already installed. Reinstalling.."
    helm delete --purge frconfig || exit 1
  fi
  helm install --name frconfig forgeops/helm/frconfig --values values/frconfig.yaml || exit 1

  printStepTitle "Cleaning up..."
  echo "Deleting:"
  rm -v forgeops/helm/frconfig/secrets/id_rsa || exit 1
}

function deploy() {
  printStepTitle "Deploying ForgeRock to Kubernetes..."

  checkDependencies
  startMinikube

  printStepTitle "Installing the directory server for the configuration store Helm chart..."
  helm install --name configstore forgeops/helm/ds --values values/configstore.yaml || exit 1

  printStepTitle "Installing the directory server for the user store Helm chart..."
  helm install --name userstore forgeops/helm/ds --values values/userstore.yaml || exit 1

  printStepTitle "Installing the directory server for the CTS store Helm chart..."
  helm install --name ctsstore forgeops/helm/ds --values values/ctsstore.yaml || exit 1

  printStepTitle "Installing the AM and Amster Helm chart..."
  helm install --name openam forgeops/helm/openam --values values/openam.yaml || exit 1
  helm install --name amster forgeops/helm/amster --values values/amster.yaml || exit 1

  printStepTitle "Listing the current pods..."
  kubectl get pods || exit 1

  printStepTitle "Service Information Summary"
  FR_HOST=$(kubectl get ingress -o jsonpath="{.items[0].spec.rules[0].host}")
  FR_IP=$(minikube ip)
  echo "Please add the following line to your /etc/hosts file:"
  echo -e "$FR_IP\t$FR_HOST"
  echo
  echo "AM will be available at: https://$FR_HOST/XUI/?service=adminconsoleservice"
  echo "Your \"amadmin\" user password: $(kubectl get configmaps amster-config -o yaml | grep -o 'adminPwd \"\(.*\)\"')"
}

function undeploy() {
  printStepTitle "Undeploying ForgeRock..."
  forgeops/bin/remove-all.sh -N || exit 1
}

function cleanup() {
  printStepTitle "Restoring local Docker settings..."
  eval "$(minikube -p minikube docker-env --shell bash -u)"
}

# ======================================================================================================================
# ======================================================================================================================
trap cleanup SIGINT SIGTERM SIGUSR1 EXIT
printHeader

# extract the COMMAND
case "$1" in
"")
  echo "No command provided!"
  printUsage
  exit 1
  ;;
build-downloader)
  buildFRDownloader
  exit 0
  ;;
build-fr-all)
  buildFRAppsImages
  exit 0
  ;;
configure)
  configure
  exit 0
  ;;
deploy)
  deploy
  exit 0
  ;;
undeploy)
  undeploy
  exit 0
  ;;
redeploy)
  undeploy && configure && deploy
  exit 0
  ;;
*)
  echo "Unknown command \"$1\"!"
  printUsage
  exit 1
  ;;
esac
