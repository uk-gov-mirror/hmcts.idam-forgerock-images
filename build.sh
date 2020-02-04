#!/usr/bin/env bash
# -------------------------
# User script configuration
# -------------------------

# The group part of Docker image tag used to tag generated files
DOCKER_TAG_GROUP="fr-local"

# The list of required binary files, for help see the README.md file
FORGEROCK_AM_FILE=AM-6.5.2.2.war
FORGEROCK_AMSTER_FILE=Amster-6.5.2.2.zip
FORGEROCK_DS_FILE=DS-6.5.2.zip
FORGEROCK_IDM_FILE=IDM-6.5.0.2.zip

# The name of the branch to take the configuration from (cnp-idam-packer repo)
CONFIGURATION_BRANCH="master"

# ---------------------------------------------------------------
# END OF CONFIGURATION - DO NOT EDIT BELOW THIS LINE
# (unless you're modifying the script and know what you're doing)
# ---------------------------------------------------------------
FORGEROCK_REQUIRED_BINARIES=("$FORGEROCK_AM_FILE" "$FORGEROCK_AMSTER_FILE" "$FORGEROCK_DS_FILE" "$FORGEROCK_IDM_FILE")

# Prints a pretty text header
function print-pretty-header() { echo -e "\n>> $1"; }

# Builds a Docker image using Dockerfile present in a provided directory
function build-docker-image() {
  print-pretty-header "Building Docker image for \"$1\""
  [ -f "$1/Dockerfile" ] || { echo "No Dockerfile found in directory \"$1\"!" && exit 1; }
  DOCKER_TAG_FINAL="${DOCKER_TAG_GROUP}-${1}:${CONFIG_VERSION}"
  echo "Building the image and tagging as \"$DOCKER_TAG_FINAL\"."
  docker build --tag "$DOCKER_TAG_FINAL" "./$1" || { echo "Docker build FAILED!" && exit 1; }
}

# Performs a git operation on the config sub-module
function git-config() { git --git-dir="./cnp-idam-packer/.git" $@; }

# Updates the config submodule
function update-config() {
  print-pretty-header "Updating config from git submodule ($CONFIGURATION_BRANCH branch).."
  { git-config fetch && git-config merge "origin/$CONFIGURATION_BRANCH"; } || { echo "Git submodule update failed!" && exit 1; }
  CONFIG_VERSION=$(git-config show --format="%cd" --date=format:%Y.%m.%d_%H.%M.%S)_${CONFIGURATION_BRANCH}
  echo "The configuration is currently at version \"${CONFIG_VERSION}\"."
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

function prepare() {
  print-pretty-header "Cleaning up leftover files from the previous run..."
  rm -r ./am/openam_conf/config_files ./am/openam_conf/amster.zip ./am/openam_conf/openam.war
  rm -r ./ds/opendj.zip ./ds/secrets ./ds/bootstrap
  rm -r "./idm/$FORGEROCK_IDM_FILE" ./idm/security
  echo "OK"
}

function search-and-replace() {
  sed -i '' "s/$1/$2/" "$3" || exit 1
#  true;
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
print-pretty-header "Copying AM configuration files.."
cp -R "./cnp-idam-packer/ansible/roles/forgerock_am/files/config_files/config_files" ./am/openam_conf || exit 1
echo "OK"

print-pretty-header "Copying AM binary files.."
cp "./bin/$FORGEROCK_AM_FILE" ./am/openam_conf/openam.war || exit 1
cp "./bin/$FORGEROCK_AMSTER_FILE" ./am/openam_conf/amster.zip || exit 1
echo "OK"

#build-docker-image "am"

# ========================
#            DS
# ========================

print-pretty-header "Copying DS configuration files.."
cp -R ./cnp-idam-packer/ansible/roles/forgerock_ds/files/secrets ./ds/secrets || exit 1
echo "Pa55word11" >./ds/secrets/dirmanager.pw || exit 1

mkdir -p ./ds/bootstrap/
cp -R ./cnp-idam-packer/ansible/roles/forgerock_ds/files/user_store ./ds/bootstrap/ || exit 1

# rename schema ldifs so they are imported before the others
i=0
for file in ./ds/bootstrap/user_store/*schema.ldif; do
  newFilePrefix=$(printf "%02d" $i)
  echo "Found a schema file: $(basename "$file") -> renaming to ${newFilePrefix}_$(basename "$file")"
  mv "$file" "$(dirname "$file")/${newFilePrefix}_$(basename "$file")" || exit 1
  ((i = i + 1))
done

mkdir -p ./ds/bootstrap/cfg_cts_store/setup_scripts_cfg ./ds/bootstrap/cfg_cts_store/setup_scripts_cts || exit 1
cp -R ./cnp-idam-packer/ansible/roles/forgerock_ds/templates/cfg_store/* ./ds/bootstrap/cfg_cts_store/setup_scripts_cfg || exit 1
cp -R ./cnp-idam-packer/ansible/roles/forgerock_ds/templates/cts_store/* ./ds/bootstrap/cfg_cts_store/setup_scripts_cts || exit 1

# delete 00-runme.sh.j2, superseded by 00-runme.sh which changes the script run order
rm ./ds/bootstrap/cfg_cts_store/setup_scripts_cts/00-runme.sh.j2 || exit 1

for file in ./ds/bootstrap/cfg_cts_store/setup_scripts_cfg/*.sh.j2 \
  ./ds/bootstrap/cfg_cts_store/setup_scripts_cts/*.sh.j2 \
  ./ds/bootstrap/cfg_cts_store/setup_scripts_cts/00-runme.sh; do
  search-and-replace "{{ opendj_home }}" '\$CFG_SCRIPTS\/\.\.' "$file"
  search-and-replace "--port 4444" '--port \$ADMIN_PORT' "$file"
  search-and-replace "{{ baseDN }}" '\$BASE_DN' "$file"
  search-and-replace "{{ bindDN }}" '\$USER' "$file"
  search-and-replace "--bindDN \"cn=Directory Manager\"" '--bindDN \"\$USER\"' "$file"
  search-and-replace "{{ BINDPASSWD }}" '\$PASSWORD' "$file"
  search-and-replace "\/opt\/opendj" '\$OPENDJ_ROOT' "$file"
  search-and-replace "--port 1389" '--port \$LDAP_PORT' "$file"
  search-and-replace "--hostname localhost" '--hostname \$DSHOSTNAME' "$file"
  search-and-replace "{{ openam_username }}" '\$OPENAM_USERNAME' "$file"
  search-and-replace "{{ openam_cts_username }}" '\$OPENAM_CTS_USERNAME' "$file"
  search-and-replace "{{ cts_baseDN }}" '\$CTS_BASE_DN' "$file"
done
for file in ./ds/bootstrap/cfg_cts_store/setup_scripts_cfg/*.ldif.j2 ./ds/bootstrap/cfg_cts_store/setup_scripts_cts/*.ldif.j2; do
  search-and-replace "{{ opendj_home }}" 'CFG_SCRIPTS\/\.\.' "$file"
  search-and-replace "{{ baseDN }}" 'BASE_DN' "$file"
  search-and-replace "{{ openam_username }}" 'OPENAM_USERNAME' "$file"
  search-and-replace "{{ openam_cts_username }}" 'OPENAM_CTS_USERNAME' "$file"
  search-and-replace "{{ cts_baseDN }}" 'CTS_BASE_DN' "$file"
  search-and-replace "{{ openam_cts_password }}" 'OPENAM_PASSWORD' "$file"
  search-and-replace "{{ openam_password }}" 'OPENAM_PASSWORD' "$file"
done

# strip all .j2 files of its suffix
for file in ./ds/bootstrap/cfg_cts_store/setup_scripts_cfg/*.j2 ./ds/bootstrap/cfg_cts_store/setup_scripts_cts/*.j2; do
  mv -- "$file" "${file%.j2}" || exit 1
done

# get the pwd blacklist
cp ./cnp-idam-packer/ansible/shared-templates/blacklist.txt.j2 ./ds/bootstrap/blacklist.txt || exit 1
echo "OK"

print-pretty-header "Copying DS binary files.."
cp "./bin/$FORGEROCK_DS_FILE" ./ds/opendj.zip || exit 1
echo "OK"

#build-docker-image "ds"

# ========================
#           IDM
# ========================
print-pretty-header "Copying IDM binary files.."
cp "./bin/$FORGEROCK_IDM_FILE" ./idm/ || exit 1
echo "OK"

#build-docker-image "idm"

# ========================
#         POSTGRES
# ========================
#build-docker-image "postgres"
