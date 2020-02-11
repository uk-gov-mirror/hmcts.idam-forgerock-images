#!/usr/bin/env bash

FR_API_KEY="APgwAVvh21GZEng5zSUBgmpMRg8dsW8feBCfL"

# ======================================================================================================================
# ======================================================================================================================
function qecho {
  [ "$OPTION_QUIET" = "true" ] || echo $@
}

function title {
  echo -e "==> $1"
}

function check_dependency {
  printf -- "- %-15s" "$1"
  [ -x "$(command -v "$1")" ] || { printf -- "not found!\n" && exit 1; }
  printf -- "ok\n"
}

function check_dependencies {
  title "Checking dependencies..."
  check_dependency git
  check_dependency docker
  check_dependency kubectl
  check_dependency helm
  check_dependency kubectx
  check_dependency stern
}

function show_help {
  printf "Usage: %s [-q] command\n" "$0"
  echo "Where command is one of:"
}

function initialise {
  title "Initialising..."
}

function build_downloader {
  title "Building the ForgeRock downloader Docker Image.."
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
init)
  initialise
  ;;
build-downloader)
  build_downloader
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
