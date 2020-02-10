#!/usr/bin/env bash

function title() {
  echo -e "==> $1"
}

function build_docker_image() {
  echo "- Building \"$1\", tagging as \"$2\"..."
  docker build --tag "$2" "./$1" || exit 1
}
# ==================================================================================================================

title "Building initial template Docker image..."
build_docker_image "docker/am" "fr-local-am-template:latest"

title "Cleaning the WORK folder..."
rm -rf work/* || exit 1
mkdir -p work || exit 1

title "Copying local Ansible playbook..."
cp -R ansible work || exit 1

title "Copying Ansible roles from configuration..."
cp -R cnp-idam-packer/ansible/roles/ work/ansible/roles/ || exit 1

title "Running the local Ansible Playbook..."
ansible-playbook -v -i work/ansible/inventory.yml work/ansible/playbook.yml