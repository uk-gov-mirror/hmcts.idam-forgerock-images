#!/usr/bin/env bash
# -------------------------
# User script configuration
# -------------------------

# The group part of Docker image tag used to tag generated files
DOCKER_TAG_GROUP="forgerock-local"

# The list of required binary files, for help see the README.md file
FORGEROCK_REQUIRED_BINARIES=(AM-6.5.2.2.war Amster-6.5.2.2.zip DS-6.5.2.zip IDM-6.5.0.2.zip)

# The name of the configuration repository (git submodule)
CONFIGURATION_REPOSITORY_NAME="cnp-idam-packer"

# The name of the branch to take the configuration from (cnp-idam-packer repo)
CONFIGURATION_BRANCH="master"

# ---------------------------------------------------------------
# END OF CONFIGURATION - DO NOT EDIT BELOW THIS LINE
# (unless you're modifying the script and know what you're doing)
# ---------------------------------------------------------------

# Prints a pretty text header
function print-pretty-header() { echo -e ">> $1"; }

# Builds a Docker image using Dockerfile present in a provided directory
function build-docker-image() {
  print-pretty-header "Building Docker image for \"$1\""
  [ -f "$1/Dockerfile" ] || { echo "No Dockerfile found in directory \"$1\"!" && exit 1; }
  DOCKER_TAG_FINAL="${DOCKER_TAG_GROUP}-${1}:${CONFIG_VERSION}"
  echo "Building the image and tagging as \"$DOCKER_TAG_FINAL\"."
  docker build --tag "$DOCKER_TAG_FINAL" "./$1" || { echo "Docker build FAILED!" && exit 1; }
}

# Performs a git operation on the config sub-module
function git-config() { git --git-dir="./$CONFIGURATION_REPOSITORY_NAME/.git" $@; }

# Updates the config submodule
function update-config() {
  print-pretty-header "Updating config from \"$CONFIGURATION_REPOSITORY_NAME\".."
  { git-config fetch && git-config merge "origin/$CONFIGURATION_BRANCH"; } || { echo "Git submodule update failed!" && exit 1; }
  CONFIG_VERSION=$(git-config show --format="%cd" --date=format:%Y.%m.%d_%H.%M.%S)_$CONFIGURATION_BRANCH
  echo "The configuration is currently at version \"${CONFIG_VERSION}\" (the last commit timestamp + branch)."
}

# Makes sure that all the required binary files are present in the bin/ directory
function check-binary-files-exist() {
  print-pretty-header "Checking for ForgeRock binary files..."
  local error=false
  for file in ${FORGEROCK_REQUIRED_BINARIES[*]}; do
    [ -f "bin/$file" ] || { error=true && echo "- A binary file \"$file\" has not been found!"; }
  done
  [ "$error" = true ] && echo -e "\nSome binary files are missing. Please make sure they're available in the bin/ directory." && exit 1
  echo "OK"
}

# ---------------------
# The build script body
# ---------------------

echo "IDAM Forgerock Images Building Script"
echo "====================================="

check-binary-files-exist
update-config

cp ./bin/AM-6.5.2.2.war ./am/openam_conf/openam.war
cp ./bin/Amster-6.5.2.2.zip ./am/openam_conf/amster.zip
build-docker-image "am"

#build-docker-image "ds"
#build-docker-image "idm"

build-docker-image "postgres"
