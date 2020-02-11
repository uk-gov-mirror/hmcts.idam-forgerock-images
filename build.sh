#!/usr/bin/env bash

FR_VERSION=6.5.2

# ======================================================================================================================
# ======================================================================================================================
function qecho() {
  [ "$OPTION_QUIET" = "true" ] || echo $@
}

function title() {
  echo -e "==> $1"
}

function check_dependency() {
  printf -- "- %-15s" "$1"
  [ -x "$(command -v "$1")" ] || { printf -- "not found!\n" && exit 1; }
  printf -- "ok\n"
}

function check_dependencies() {
  title "Checking dependencies..."
  #todo
  check_dependency git
  check_dependency docker
  check_dependency kubectl
  check_dependency helm
  check_dependency kubectx
  check_dependency stern
}

function require_api_key() {
  [ -z "$FR_API_KEY" ] && { echo "This operation requires the FR_API_KEY variable!" && exit 1; }
  qecho "Found FR_API_KEY."
}

function show_help() {
  printf "Usage: %s [-q] command\n" "$0"
  echo "Options:"
  echo -e "\tq\tQuiet"
  echo
  echo "Where command is one of:"
  #todo
}

function initialise() {
  title "Initialising..."
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

# ======================================================================================================================
# ======================================================================================================================
OPTIND=1 # Reset in case getopts has been used previously in the shell.
# initialise variables
OPTION_QUIET=false

while getopts "h?q" option; do
  case "$option" in
  h | \?)
    show_help
    exit 0
    ;;
  q)
    OPTION_QUIET=true
    ;;
  esac
done

shift $((OPTIND - 1))
[ "${1:-}" = "--" ] && shift

# extract the COMMAND
case "$1" in
"")
  echo "No command provided!"
  show_help
  exit 1
  ;;
init)
  initialise
  ;;
build-downloader)
  build_downloader
  ;;
build-fr-all)
  build_fr_all
  ;;
*)
  echo "Unknown command \"$1\"!"
  show_help
  exit 1
  ;;
esac

# ======================================================================================================================
# ======================================================================================================================

#check_dependencies

#title "Applying workaround for Minikube..."
#minikube ssh sudo ip link set docker0 promisc on
