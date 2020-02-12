#!/usr/bin/env bash

FR_VERSION=6.5.2

# ======================================================================================================================
# ======================================================================================================================
function title() {
  echo -e "\n==> $1"
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
  printf "  %-${padding}s\tUndeploys ForgeRock locally using Minikube.\n" "undeploy"
}

DOCKER_LOCAL_REGISTRY="localhost"
function ensure_local_docker_registry() {
  REGISTRY_RUNNING=$(docker inspect -f '{{.State.Running}}' registry)
  if [ ! "$REGISTRY_RUNNING" = "true" ]; then
    title "Starting local Docker registry..."
    docker run -d -p 5000:5000 --restart=always --name registry registry:2 || exit 1
  fi
}

function build_downloader() {
  title "Building the ForgeRock downloader Docker Image.."
  require_variable "FR_API_KEY"
  docker build --no-cache --build-arg API_KEY=$FR_API_KEY --tag forgerock/downloader -f forgeops/docker/downloader/Dockerfile forgeops/docker/downloader || exit 1
}

function build_and_push() {
  title "Building $1 Docker Image.."
  ensure_local_docker_registry

  docker build --tag forgerock/$1:$FR_VERSION -f forgeops/docker/$1/Dockerfile forgeops/docker/$1 || exit 1
  #  docker build --no-cache --tag forgerock/$1:$FR_VERSION -f forgeops/docker/$1/Dockerfile forgeops/docker/$1 || exit 1

  title "Tagging and pushing..."
  docker tag forgerock/$1:$FR_VERSION $DOCKER_LOCAL_REGISTRY:5000/forgerock/$1:$FR_VERSION || exit 1
  docker push $DOCKER_LOCAL_REGISTRY:5000/forgerock/$1:$FR_VERSION || exit 1
}

function build_fr_all() {
  title "Building all the ForgeRock Docker Images..."

  build_and_push openam
  build_and_push openidm
  build_and_push ds
}

function configure() {
  title "Configuring local Kubernetes..."
  check_dependencies

  title "Starting a Minikube cluster.."
  if [ "$(minikube status | grep -c "Stopped\|Nonexistent")" = "0" ]; then
    echo "Minikube already running."
  else
    minikube start --memory=8192 --disk-size=30g --vm-driver=virtualbox --bootstrapper kubeadm --kubernetes-version=v1.15.0 || exit 1
  fi

  title "Setting up Helm on Minikube..."
  if [ -z "$(kubectl get pods --all-namespaces | grep tiller-deploy)" ]; then
    helm init --upgrade --service-account default || exit 1
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
  require_variable CONFIG_REPO_PRIVATE_KEY_PATH
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
  # TODO implement
  title "Deploying ForgeRock to Kubernetes..."

  title "Installing the directory server for the configuration store..."
  helm install forgeops/helm/ds --values values/configstore.yaml || exit 1

  title "Installing the directory server for the user store..."
  helm install forgeops/helm/ds --values values/userstore.yaml || exit 1

  title "Installing the directory server for the CTS store..."
  helm install forgeops/helm/ds --values values/ctsstore.yaml || exit 1
}

function undeploy() {
  title "Undeploying ForgeRock..."
  forgeops/bin/remove-all.sh -N || exit 1
}

# ======================================================================================================================
# ======================================================================================================================
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
*)
  echo "Unknown command \"$1\"!"
  show_help
  exit 1
  ;;
esac
