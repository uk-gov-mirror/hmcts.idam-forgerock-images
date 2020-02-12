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

function build_downloader() {
  title "Building the ForgeRock downloader Docker Image.."
  require_variable "FR_API_KEY"
  docker build --no-cache --build-arg API_KEY=$FR_API_KEY --tag forgerock/downloader -f forgeops/docker/downloader/Dockerfile forgeops/docker/downloader || exit 1
}

function build_fr_all() {
  title "Building all the ForgeRock Docker Images..."

  # AM
  docker build --tag forgerock/openam:$FR_VERSION -f forgeops/docker/openam/Dockerfile forgeops/docker/openam || exit 1
  # IDM
  docker build --tag forgerock/openidm:$FR_VERSION -f forgeops/docker/openidm/Dockerfile forgeops/docker/openidm || exit 1
  # DS
  docker build --tag forgerock/ds:$FR_VERSION -f forgeops/docker/ds/Dockerfile forgeops/docker/ds || exit 1
}

function configure() {
  title "Configuring local Kubernetes..."
  check_dependencies

  title "Starting a Minikube cluster.."
  #  minikube start --memory=8192 --disk-size=30g --vm-driver=virtualbox --bootstrapper kubeadm --kubernetes-version=v1.17.2 || exit 1

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
  # TODO impleent
  true
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
