#!/usr/bin/env bash
# -------------------------
# User script configuration
# -------------------------

# The group part of Docker image tag used to tag generated files
: ${DOCKER_IMAGE_PREFIX:=fr-local}

# The list of required binary files, for help see the README.md file
: ${FORGEROCK_AM_FILE:=AM-6.5.2.2.war}
: ${FORGEROCK_AMSTER_FILE:=Amster-6.5.2.2.zip}
: ${FORGEROCK_DS_FILE:=DS-6.5.2.zip}
: ${FORGEROCK_IDM_FILE:=IDM-6.5.0.2.zip}

: ${FORGEROCK_BINARIES_DIR:=bin}

# The name of the branch to take the configuration from (cnp-idam-packer repo)
: ${CONFIGURATION_BRANCH:=preview}

# ---------------------------------------------------------------
# END OF CONFIGURATION - DO NOT EDIT BELOW THIS LINE
# (unless you're modifying the script and know what you're doing)
# ---------------------------------------------------------------
FORGEROCK_REQUIRED_BINARIES=("$FORGEROCK_AM_FILE" "$FORGEROCK_AMSTER_FILE" "$FORGEROCK_DS_FILE" "$FORGEROCK_IDM_FILE")

# Prints a pretty text header
function header() { echo -e "\n==> $1"; }

# Builds a Docker image using Dockerfile present in a provided directory
function build-docker-image() {
  header "Building Docker image for \"$1\""
  [ -f "$1/Dockerfile" ] || { echo "No Dockerfile found in directory \"$1\"!" && exit 1; }
  DOCKER_TAG_FINAL="${DOCKER_IMAGE_PREFIX}-${1}:${CONFIG_VERSION}"
  DOCKER_TAG_LATEST="${DOCKER_IMAGE_PREFIX}-${1}:latest"
  echo "Building the image and tagging as \"$DOCKER_TAG_FINAL\" and \"$DOCKER_TAG_LATEST\"."
  docker build --tag "$DOCKER_TAG_FINAL" --tag "$DOCKER_TAG_LATEST" "./$1" || { echo "Docker build ($1) FAILED!" && exit 1; }
}

# Performs a git operation on the config sub-module
function git-config() { git --git-dir="./cnp-idam-packer/.git" $@; }

# Returns the current git branch
function git-branch() { git-config rev-parse --abbrev-ref HEAD; }

# Updates the config submodule
function update-config() {
  header "Updating config from git submodule.."
  CURR_BRANCH="$(git-branch)"
  [ "$CURR_BRANCH" = "$CONFIGURATION_BRANCH" ] || { echo "The current branch of the configuration repository is \"$CURR_BRANCH\", expected: \"$CONFIGURATION_BRANCH\"" && exit 1; }
#  { git-config fetch && git-config pull; } || { echo "Git submodule update failed!" && exit 1; }
  CONFIG_VERSION=$(git-config rev-parse HEAD)_${CONFIGURATION_BRANCH}
 ## CONFIG_VERSION=1
  echo "The configuration is currently at version \"${CONFIG_VERSION}\"."
}

# Makes sure that all the required binary files are present in the binary directory
function check-binary-files-exist() {
  header "Checking for ForgeRock binary files..."
  local error=false
  for file in ${FORGEROCK_REQUIRED_BINARIES[*]}; do
    [ -f "$FORGEROCK_BINARIES_DIR/$file" ] || { error=true && echo "- A binary file \"$file\" has not been found!"; }
  done
  [ "$error" = true ] && echo -e "\nSome binary files are missing. Please make sure they're available in the binary directory." && exit 1
  echo "OK"
}

function prepare() {
  header "Cleaning up leftover files from the previous run..."
  rm -r ./am/openam_conf/config_files ./am/openam_conf/amster.zip ./am/openam_conf/openam.war
  rm -r ./ds/opendj.zip ./ds/secrets ./ds/bootstrap
  rm -r "./idm/$FORGEROCK_IDM_FILE" ./idm/build/*
  echo "OK"
}

function search-and-replace() {
   perl -p -i -e 's/'"$1"'/'"$2"'/g' $3
}

# checks for the files still containing {{
function find-unprocessed-ansible-files() {
  UNPROCESSED_FILES=$(find "$1" -type f -print0 | xargs -0 grep -l "{{")
  [ -z "$UNPROCESSED_FILES" ] || {
    echo "Files still containing Ansible variable placeholders have been found:"
    echo "$UNPROCESSED_FILES" | tr " " "\n"
    echo "Please review the files and make necessary changes to the script."
    exit 1
  }
}

# ----------------------------------------------------------------------------------------------------------------------
echo "============================================"
echo "IDAM ForgeRock Docker Images Building Script"
echo "============================================"

prepare

check-binary-files-exist
update-config

# ========================
#            AM
# ========================
header "Copying AM configuration files.."
AM_SRC="./cnp-idam-packer/ansible/roles/forgerock_am/files/config_files/config_files"
[ "$CONFIGURATION_BRANCH" = "preview" ] && AM_SRC="./cnp-idam-packer/ansible/roles/forgerock_am/files/config_files"
cp -R $AM_SRC ./am/openam_conf || exit 1
echo "OK"

header "Copying AM binary files.."
cp "$FORGEROCK_BINARIES_DIR/$FORGEROCK_AM_FILE" ./am/openam_conf/openam.war || exit 1
cp "$FORGEROCK_BINARIES_DIR/$FORGEROCK_AMSTER_FILE" ./am/openam_conf/amster.zip || exit 1
echo "OK"

#Variable substitutions
search-and-replace "\"org.forgerock.services.cts.store.ssl.enabled\" : true" "\"org.forgerock.services.cts.store.ssl.enabled\" : false"  "./am/openam_conf/config_files/global/DefaultCtsDataStoreProperties.json"
search-and-replace "\"sun-idrepo-ldapv3-config-connection-mode\" : \"LDAPS\"" "\"sun-idrepo-ldapv3-config-connection-mode\" : \"AMSTER{ldapProtocol}\"" "./am/openam_conf/config_files/realms/root-hmcts/OpenDJ/OpenDJ.json"
search-and-replace "forgerock-ds-userstore-2.AMSTER{domainSuffix}:AMSTER{ds_user_port}|server1" "AMSTER{ds_user_host}:AMSTER{ldapcfgUserStorePort}" "./am/openam_conf/config_files/realms/root-hmcts/OpenDJ/OpenDJ.json"

# Customize openam auth hotp jar file
bash ./am/customize_jar.sh

build-docker-image "am"

# ========================
#            DS
# ========================

header "Copying DS configuration files.."
DS_SRC="./cnp-idam-packer/ansible/roles/forgerock_ds"
DS_TRG="./ds/bootstrap/cfg_cts_store"

cp -R $DS_SRC/files/secrets ./ds/secrets || exit 1
echo "Pa55word11" >./ds/secrets/dirmanager.pw || exit 1

mkdir -p ./ds/bootstrap/
cp -R $DS_SRC/files/user_store ./ds/bootstrap/ || exit 1

# rename schema ldifs so they are imported before the others
i=0
for file in ./ds/bootstrap/user_store/*schema.ldif; do
  newFilePrefix=$(printf "%02d" $i)
  echo "Found a schema file: $(basename "$file") -> renaming to ${newFilePrefix}_$(basename "$file")"
  mv "$file" "$(dirname "$file")/${newFilePrefix}_$(basename "$file")" || exit 1
  ((i = i + 1))
done

mkdir -p $DS_TRG/setup_scripts_cfg $DS_TRG/setup_scripts_cts || exit 1
cp -R $DS_SRC/templates/cfg_store/* $DS_TRG/setup_scripts_cfg || exit 1
cp -R $DS_SRC/templates/cts_store/* $DS_TRG/setup_scripts_cts || exit 1

# delete 00-runme.sh.j2, superseded by 00-runme.sh which changes the script run order
rm $DS_TRG/setup_scripts_cts/00-runme.sh.j2 || exit 1

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# SUBSTITUTION MOVED TO run.sh

#for file in $DS_TRG/setup_scripts_cfg/*.sh.j2 \
#  $DS_TRG/setup_scripts_cts/*.sh.j2 \
#  $DS_TRG/setup_scripts_cts/00-runme.sh; do
#  search-and-replace "{{ opendj_home }}" '\$CFG_SCRIPTS\/\.\.' "$file"
#  search-and-replace "--port 4444" '--port \$ADMIN_PORT' "$file"
#  search-and-replace "{{ baseDN }}" '\$BASE_DN' "$file"
#  search-and-replace "{{ bindDN }}" '\$USER' "$file"
#  search-and-replace "--bindDN \"cn=Directory Manager\"" '--bindDN \"\$USER\"' "$file"
#  search-and-replace "{{ BINDPASSWD }}" '\$PASSWORD' "$file"
#  search-and-replace "\/opt\/opendj" '\$OPENDJ_ROOT' "$file"
#  search-and-replace "--port 1389" '--port \$LDAP_PORT' "$file"
#  search-and-replace "--hostname localhost" '--hostname \$DSHOSTNAME' "$file"
#  search-and-replace "{{ openam_username }}" '\$OPENAM_USERNAME' "$file"
#  search-and-replace "{{ openam_cts_username }}" '\$OPENAM_CTS_USERNAME' "$file"
#  search-and-replace "{{ cts_baseDN }}" '\$CTS_BASE_DN' "$file"
#done
#for file in $DS_TRG/setup_scripts_cfg/*.ldif.j2 $DS_TRG/setup_scripts_cts/*.ldif.j2; do
#  search-and-replace "{{ opendj_home }}" 'CFG_SCRIPTS\/\.\.' "$file"
#  search-and-replace "{{ baseDN }}" 'BASE_DN' "$file"
#  search-and-replace "{{ openam_username }}" 'OPENAM_USERNAME' "$file"
#  search-and-replace "{{ openam_cts_username }}" 'OPENAM_CTS_USERNAME' "$file"
#  search-and-replace "{{ cts_baseDN }}" 'CTS_BASE_DN' "$file"
#  search-and-replace "{{ openam_cts_password }}" 'OPENAM_PASSWORD' "$file"
#  search-and-replace "{{ openam_password }}" 'OPENAM_PASSWORD' "$file"
#done
#find-unprocessed-ansible-files "$DS_TRG"

# strip all .j2 files of its suffix
for file in $DS_TRG/setup_scripts_cfg/*.j2 $DS_TRG/setup_scripts_cts/*.j2; do
  mv -- "$file" "${file%.j2}" || exit 1
done

# get the pwd blacklist
cp ./cnp-idam-packer/ansible/shared-templates/blacklist.txt.j2 ./ds/bootstrap/blacklist.txt || exit 1
echo "OK"

header "Copying DS binary files.."
cp "$FORGEROCK_BINARIES_DIR/$FORGEROCK_DS_FILE" ./ds/opendj.zip || exit 1
echo "OK"

build-docker-image "ds"

# ========================
#           IDM
# ========================

header "Building IDM config.."

./idm/build_config.sh

echo "OK"

header "Copying IDM binary files.."
cp "$FORGEROCK_BINARIES_DIR/$FORGEROCK_IDM_FILE" ./idm/ || exit 1
echo "OK"

build-docker-image "idm"

# ========================
#         POSTGRES
# ========================
build-docker-image "postgres"
