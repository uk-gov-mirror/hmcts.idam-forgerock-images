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
#build_docker_image "docker/am" "fr-local-am-base:latest"

# todo build the rest of base images

title "Running Ansible for AM..."
if [ -z "$1" ]; then
  ansible-playbook -v -i ansible/inventory.yml ansible/am-playbook.yml
else
  echo "Resuming from task: $1."
  ansible-playbook -v -i ansible/inventory.yml ansible/am-playbook.yml --start-at-task="$1"
fi
