#!/usr/bin/env bash

FR_VERSION=6.5.2

# ======================================================================================================================
# ======================================================================================================================
function title() {
  echo -e "\n==> $1"
}

function header() {
  cat <<EOF
================================
FORGEROCK IMAGES BUILDING SCRIPT
================================
EOF
}

function check_dependency() {
  printf -- "- %-15s" "$1"
  [ -x "$(command -v "$1")" ] || { printf -- "not found!\n" && exit 1; }
  printf -- "ok\n"
}

function check_dependencies() {
  echo "Checking dependencies..."
  check_dependency git
  check_dependency docker
  check_dependency kubectl
  check_dependency helm
  check_dependency kubectx
  check_dependency stern
  check_dependency minikube
  check_dependency kubens
  check_dependency VirtualBox
}

function require_variable() {
  [ -z "${!1}" ] && { echo "This operation requires the \"$1\" variable which was not found (or was empty)!" && exit 1; }
  echo "Found \$${1}."
}

function show_help() {
  padding=20
  printf "Usage: %s command\n" "$0"
  printf "Where command is one of:\n"
  printf "  %-${padding}s\tBuilds a base downloader Docker Image, required for building all other images.\n" "build-downloader"
  printf "  %-${padding}s\tBuilds all required ForgeRock Docker Images, required a Downloader image as a base image.\n" "build-fr-all"
  printf "  %-${padding}s\tConfigures local Kubernetes for ForgeRock deployment.\n" "configure"
  printf "  %-${padding}s\tDeploys ForgeRock locally using Minikube. All images need to be built beforehand.\n" "deploy"
  printf "  %-${padding}s\tRedeploys ForgeRock locally using Minikube. Combines undeploy, configure and deploy.\n" "redeploy"
  printf "  %-${padding}s\tUndeploys ForgeRock locally using Minikube.\n" "undeploy"
  printf "  %-${padding}s\tUpdates the ForgeRock configuration using IDAM Packer repository.\n" "update-fr-config"
}

function turn_k8s_docker_on() {
  title "Switching to the internal Minikube Docker registry..."
  eval "$(minikube -p minikube docker-env --shell bash)" || exit 1
}

function build_downloader() {
  title "Building the ForgeRock downloader Docker Image.."
  require_variable "FR_API_KEY"
  turn_k8s_docker_on

  docker build --build-arg API_KEY=$FR_API_KEY --tag forgerock/downloader -f forgeops/docker/downloader/Dockerfile forgeops/docker/downloader || exit 1
}

function build_and_push() {
  title "Building $1 Docker Image.."
  turn_k8s_docker_on

  docker build --tag forgerock/$1:$FR_VERSION -f forgeops/docker/$1/Dockerfile forgeops/docker/$1 || exit 1
}

function build_fr_all() {
  title "Building all the ForgeRock Docker Images..."

  build_and_push openam
  build_and_push openidm
  build_and_push ds
  build_and_push amster
}

function configure() {
  title "Configuring local Kubernetes..."
  check_dependencies
  require_variable CONFIG_REPO_PRIVATE_KEY_PATH

  title "Starting a Minikube cluster.."
  if [ "$(minikube status | grep -c "Stopped\|Nonexistent")" = "0" ]; then
    echo "Minikube already running."
  else
    minikube start --memory=8192 --disk-size=30g --vm-driver=virtualbox --bootstrapper kubeadm --kubernetes-version=v1.15.0 || exit 1
  fi

  title "Setting up Helm on Minikube..."
  if [ -z "$(kubectl get pods --all-namespaces | grep tiller-deploy)" ]; then
    helm init --upgrade --service-account default || exit 1
    echo "Sleeping to give Tiller time to start.."
    sleep 10
  else
    echo "Already set up."
  fi

  title "Enabling Minikube Ingress Controller..."
  minikube addons enable ingress || exit 1

  title "Installing the Certificate Manager..."
  if [ -z "$(kubectl get customresourcedefinitions | grep certmanager)" ]; then
    helm install stable/cert-manager --namespace kube-system --version v0.5.0 || exit 1
  else
    echo "Already installed."
  fi

  title "Creating a Kubernetes namespace..."
  if [ -z "$(kubectl get namespaces | grep forgerock-local)" ]; then
    kubectl create namespace forgerock-local || exit 1
  else
    echo "Namespace already exists."
  fi

  title "Switching namespaces..."
  kubens forgerock-local || exit 1

  title "Configuring the Configuration Repository Private Key..."
  if [ -f "$CONFIG_REPO_PRIVATE_KEY_PATH" ]; then
    cp -v "$CONFIG_REPO_PRIVATE_KEY_PATH" forgeops/helm/frconfig/secrets/id_rsa || exit 1
  else
    echo "File not found: $CONFIG_REPO_PRIVATE_KEY_PATH"
    exit 1
  fi

  title "Installing frconfig Helm Chart..."
  if [ -z "$(helm list --all | grep frconfig)" ]; then
    helm install --name frconfig forgeops/helm/frconfig --values values/frconfig.yaml || exit 1
  else
    echo "Already installed."
  fi

  title "Cleaning up..."
  rm -v forgeops/helm/frconfig/secrets/id_rsa || exit 1
}

function deploy() {
  title "Deploying ForgeRock to Kubernetes..."

  title "Installing the directory server for the configuration store Helm chart..."
  helm install --name configstore forgeops/helm/ds --values values/configstore.yaml || exit 1

  title "Installing the directory server for the user store Helm chart..."
  helm install --name userstore forgeops/helm/ds --values values/userstore.yaml || exit 1

  title "Installing the directory server for the CTS store Helm chart..."
  helm install --name ctsstore forgeops/helm/ds --values values/ctsstore.yaml || exit 1

  title "Installing the AM and Amster Helm chart..."
  helm install --name openam forgeops/helm/openam --values values/openam.yaml || exit 1
  helm install --name amster forgeops/helm/amster --values values/amster.yaml || exit 1

  title "Listing the current pods..."
  kubectl get pods || exit 1

  #  title "Describing Ingress Controller..."
  #  kubectl describe ingress || exit 1

  title "Service Information Summary"
  FR_HOST=$(kubectl get ingress -o jsonpath="{.items[0].spec.rules[0].host}")
  FR_IP=$(minikube ip)
  echo "Please add the following line to your /etc/hosts file:"
  echo -e "$FR_IP\t$FR_HOST"
  echo
  echo "AM will be available at: https://$FR_HOST/XUI/?service=adminconsoleservice"
  echo "Your \"amadmin\" user password: $(kubectl get configmaps amster-config -o yaml | grep -o 'adminPwd \"\(.*\)\"')"
  echo
  echo "NOTE: Please remember to set up your browser/system to always trust FR self-signed certificate!"
  echo "      (more info: https://www.robpeck.com/2010/10/google-chrome-mac-os-x-and-self-signed-ssl-certificates/)"
}

function undeploy() {
  title "Undeploying ForgeRock..."
  forgeops/bin/remove-all.sh -N || exit 1
}

function cleanup() {
  eval "$(minikube -p minikube docker-env --shell bash -u)"
}

function update-fr-config() {
  title "Updating ForgeRock configuration based on IDAM Packer..."
  printf "Clearing the old files..."
  CFG_DIR=forgeops-config/dev
  rm -Rf $CFG_DIR/am/* || exit 1
  rm -Rf $CFG_DIR/ds/* || exit 1
  rm -Rf f$CFG_DIR/idm/* || exit 1
  printf " OK\n"
  printf "Copying AM configuration..."
  cp -r cnp-idam-packer/ansible/roles/forgerock_am/files/config_files/* $CFG_DIR/am/ || exit 1
  printf " OK\n"

  git -C forgeops-config status
  echo "The configuration has been updated. Please remember to git commit/push to make the changes take effect."
}

# ======================================================================================================================
# ======================================================================================================================
trap cleanup SIGINT SIGTERM SIGUSR1 EXIT
header

# extract the COMMAND
case "$1" in
"")
  echo "No command provided!"
  show_help
  exit 1
  ;;
build-downloader)
  build_downloader
  exit 0
  ;;
build-fr-all)
  build_fr_all
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
update-fr-config)
  update-fr-config
  exit 0
  ;;
*)
  echo "Unknown command \"$1\"!"
  show_help
  exit 1
  ;;
esac
