#!/usr/bin/env bash

FR_VERSION=6.5.2

# ======================================================================================================================
# ======================================================================================================================
function title() {
  echo -e "==> $1"
}

function check_dependency() {
  printf -- "- %-15s" "$1"
  [ -x "$(command -v "$1")" ] || { printf -- "not found!\n" && exit 1; }
  printf -- "ok\n"
}

function check_dependencies() {
  echo "Checking dependencies..."
  #todo
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

function require_api_key() {
  [ -z "$FR_API_KEY" ] && { echo "This operation requires the FR_API_KEY variable!" && exit 1; }
  echo "Found FR_API_KEY."
}

function show_help() {
  padding=20
  printf "Usage: %s command\n" "$0"
  printf "Where command is one of:\n"
  printf "\t%-${padding}s\tBuilds a base downloader Docker Image, required for building all other images.\n" "build-downloader"
  printf "\t%-${padding}s\tBuilds all required ForgeRock Docker Images, required a Downloader image as a base image.\n" "build-fr-all"
  printf "\t%-${padding}s\tDeploys ForgeRock locally using Minikube. All images need to be built beforehand.\n" "deploy"
  #todo
}

function build_downloader() {
  title "Building the ForgeRock downloader Docker Image.."
  require_api_key
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

function deploy() {
  title "Deploying ForgeRock locally using Minikube..."
  check_dependencies
  title "Starting a Minikube cluster.."
  #  minikube start --memory=8192 --disk-size=30g --vm-driver=virtualbox --bootstrapper kubeadm --kubernetes-version=v1.17.2 || exit 1
  title "Enabling Minikube Ingress Controller..."
  minikube addons enable ingress || exit 1
  title "Installing the CustomResourceDefinition resources..."
  kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/v0.13.0/deploy/manifests/00-crds.yaml || exit 1
  title "Adding JetStack Helm repository..."
  helm repo add jetstack https://charts.jetstack.io || exit 1
  title "Updating local Helm chart cache..."
  helm repo update || exit 1
  title "Installing the Certificate Manager..."
  helm install cert-manager jetstack/cert-manager --namespace kube-system --version v0.13.0 || exit 1
  title "Creating a Kubernetes namespace..."
  kubectl create namespace forgerock-local || exit 1
  title "Switching namespaces..."
  kubens my-namespace
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
deploy)
  deploy
  exit 0
  ;;
*)
  echo "Unknown command \"$1\"!"
  show_help
  exit 1
  ;;
esac
