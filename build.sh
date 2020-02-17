#!/usr/bin/env bash

function title() {
  echo -e "==> $1"
}

function build_docker_image() {
  echo "- Building \"$1\", tagging as \"$2\"..."
  docker build --tag "$2" "./$1" || exit 1
}
# ==================================================================================================================

title "Building the base Docker image for AM..."
build_docker_image "docker/am" "fr-local-am-base:latest"

title "Building the base Docker image for DS (userstore and ctsstore)..."
build_docker_image "docker/ds" "fr-local-ds-base:latest"

title "Running Ansible..."
if [ -z "$1" ]; then
  ansible-playbook -v -i ansible/inventory.yml ansible/playbook.yml
else
  echo "Resuming from task: $1."
  ansible-playbook -v -i ansible/inventory.yml ansible/playbook.yml --start-at-task="$1"
fi
