#!/usr/bin/env sh

T="/tmp/cts"
USER="cn=Directory Manager"
SRC=${SRC:-/opt/opendj/bootstrap}
DSHOSTNAME=${HOSTNAME:-localhost}
BACKEND=userRoot

cd "$OPENDJ_ROOT"

# If the pod was terminated abnormally the lock file may not have gotten cleaned up.
rm -f "$OPENDJ_ROOT"/locks/server.lock

# TODO: manage passwords
PW=`cat $DIR_MANAGER_PW_FILE`
export PASSWORD=${PW:-Pa55word11}


run_userstore_config(){
##If any optional LDIF files are present, load them.
ldif=""$OPENDJ_ROOT"/$1"

# from main.yml, listing the configuration that is not needed for a local environment
#
# start_healthcheck_tokenstore.yml -> no
# start_healthcheck_userstore.yml-> no
# iptables.yml-> no
# mount_disk.yml-> no
# opendj_users.yml-> we will just unzip the file in the container using forgerock user
# opendj-ulimit.yml-> no
# opendj_install.yml-> we will just unzip the file in the container using forgerock user
# wait for forgerock-ds-userstore-1 ldaps-port-> no
# wait for forgerock-ds-tokenstore-1 ldaps-port-> no
# I am a slave - waiting 2 mins ...-> no
# install_ldap_certificate.yml-> no
# -> no
# -> no
# -> no
#
# install_ldap_certificate.yml -> not doing for local install

## usr-setup.yml

# SET Password encyryption to SSHA512
"$OPENDJ_ROOT"/bin/dsconfig  \
  set-password-policy-prop  \
  --hostname $DSHOSTNAME \
  --port "$ADMIN_PORT" \
  --bindDN "$USER" \
  --bindPassword $PASSWORD \
  --policy-name "Default Password Policy" \
  --trustAll \
  --set default-password-storage-scheme:"Salted SHA-512" \
  --no-prompt

echo "[run.sh] #Enable SSL [localhost]"
"$OPENDJ_ROOT"/bin/dsconfig  \
  --hostname $DSHOSTNAME \
  --port "$ADMIN_PORT" \
  --bindDN "$USER" \
  --bindPassword $PASSWORD \
  --trustAll \
  -n set-crypto-manager-prop \
  --set ssl-encryption:true

# create-password-validator
"$OPENDJ_ROOT"/bin/dsconfig \
  create-password-validator \
  --hostname $DSHOSTNAME \
  --port "$ADMIN_PORT" \
  --bindDN "$USER" \
  --bindPassword $PASSWORD \
  --validator-name "Blacklisted passwords" \
  --type dictionary \
  --set enabled:true \
  --set check-substrings:false \
  --set dictionary-file:blacklist.txt \
  --trustAll \
  --no-prompt

# set-password-policy-prop
"$OPENDJ_ROOT"/bin/dsconfig \
  set-password-policy-prop \
  --policy-name "Default Password Policy" \
  --set lockout-failure-count:$LOCKOUT_FAILURE_COUNT \
  --set lockout-duration:"$PASSWORD_LOCKOUT_DURATION" \
  --set allow-pre-encoded-passwords:true \
  --hostname $DSHOSTNAME \
  --port "$ADMIN_PORT" \
  --trustAll \
  --bindDN "$USER" \
  --bindPassword $PASSWORD \
  --set password-validator:"Blacklisted passwords" \
  --no-prompt

  if [ -d "$ldif" ]; then
      echo "[run.sh] Loading LDIF files in $ldif"
      for file in "${ldif}"/*.ldif;  do
          echo "[run.sh] $USER Loading $file"
          # search + replace all placeholder variables. Naming conventions are from AM.
          sed -e "s/@BASE_DN@/$BASE_DN/" <${file}  >/tmp/file.ldif

          "$OPENDJ_ROOT"/bin/ldapmodify --bindDN "$USER"  --continueOnError -h $DSHOSTNAME -p "$LDAP_PORT" -w ${PASSWORD} --fileName /tmp/file.ldif
        echo "  "
      done
  fi
}

update_env_variable(){

  echo "[run.sh] update environment variables"
  cd $1
  pwd
  grep -rl '{{ baseDN }}' *.* | xargs sed -i'' 's/{{ baseDN }}/'$BASE_DN'/'
#  grep -rl "{{ openam_username }}" *.ldif | xargs sed -i'' 's/{{ openam_username }}/'$OPENAM_USERNAME'/'
  grep -rl '{{ openam_password }}' *.* | xargs sed -i'' 's/{{ openam_password }}/'$OPENAM_PASSWORD'/'
  grep -rl 4444 *.sh | xargs sed -i'' 's/4444/'$ADMIN_PORT'/'
 # grep -rl '{{ baseDN }}' *.sh | xargs sed -i'' 's/{{ baseDN }}/'$BASE_DN'/'
  grep -rl 1389 *.sh | xargs sed -i'' 's/1389/'$LDAP_PORT'/'
  grep -rl '{{ openam_username }}' *.* | xargs sed -i'' 's/{{ openam_username }}/'$OPENAM_USERNAME'/'
  grep -rl '{{ openam_cts_username }}' *.* | xargs sed -i'' 's/{{ openam_cts_username }}/'$OPENAM_CTS_USERNAME'/'
  grep -rl '{{ openam_cts_password }}' *.* | xargs sed -i'' 's/{{ openam_cts_password }}/'$PASSWORD'/'
  grep -rl '{{ cts_baseDN }}' *.* | xargs sed -i'' 's/{{ cts_baseDN }}/'$CTS_BASE_DN'/'
  #grep -rl '--hostname localhost' *.* | xargs sed -i'' 's/--hostname localhost/--hostname '$DSHOSTNAME'/'

  grep -rl '{{ opendj_home }}' *.sh | xargs sed -i'' 's/{{ opendj_home }}/$OPENDJ_ROOT/'
  grep -rl '{{ bindDN }}' *.sh | xargs sed -i'' 's/{{ bindDN }}/$USER/'
  grep -rl '{{ BINDPASSWD }}' *.sh | xargs sed -i'' 's/{{ BINDPASSWD }}/$PASSWORD/'

}


run_ldif_cfg_cts(){

  rm -rf $T
  mkdir $T

  # cts-setup.yml
  "$OPENDJ_ROOT"/bin/dsconfig  \
  set-password-policy-prop  \
  --hostname $DSHOSTNAME \
  --port "$ADMIN_PORT" \
  --bindDN "$USER" \
  --bindPassword "$PASSWORD" \
  --policy-name "Default Password Policy" \
  --trustAll \
  --set default-password-storage-scheme:"Salted SHA-512" \
  --no-prompt

  echo "[run.sh] do I need to sleep?"

  # shellcheck disable=SC1065
  update_env_variable $CFG_SCRIPTS
  cd $CFG_SCRIPTS

  echo "[run.sh] try to run CFG 00-runme.sh script"
  ./00-runme.sh

  update_env_variable $CTS_SCRIPTS
  cd $CTS_SCRIPTS
  echo "[run.sh] try to run CTS 00-runme.sh script (second attempt)"
  ./00-runme.sh

}




cd /opt/opendj

"$OPENDJ_ROOT"/setup \
  directory-server \
  --rootUserDN "$USER" \
  --rootUserPassword "$PASSWORD" \
  --monitorUserPassword "$PASSWORD" \
  --hostname $DSHOSTNAME \
  --adminConnectorPort "$ADMIN_PORT" \
  --ldapPort "$LDAP_PORT" \
  --ldapsPort $LDAPS_PORT \
  --enableStartTls \
  --baseDN "$BASE_DN" \
  --acceptLicense \
  --addBaseEntry

echo "[run.sh] import keystore"
keytool -importkeystore \
        -srckeystore $OPENDJ_ROOT/secrets/keystore.pkcs12 \
        -srcstoretype PKCS12 \
        -srcstorepass $PASSWORD \
        -srcalias server-cert \
        -destkeystore /opt/opendj/keystore \
        -deststorepass $PASSWORD \
        -deststoretype PKCS12 \
        -destkeypass $PASSWORD \
        -destalias server-cert \
        -no-prompt

echo "[run.sh] depending on the DS_TYPE env variable defined in the composer file, a different profile is selected"
#replace_ansible_variables
case "$DS_TYPE" in
          "userstore")
            echo "[run.sh] install DS as userStore and config store"
            run_userstore_config user_store
            ;;
          "cfgAndCts")
            echo "[run.sh] install Config store and CTS"
            run_ldif_cfg_cts
            ;;
          *)
            echo "[run.sh] if you read this message, there's something wrong.... This should not be trigger!!!"
            ;;
esac


## echo "https://backstage.forgerock.com/knowledge/kb/book/b56088823 "
#"$OPENDJ_ROOT"/bin/dsconfig set-key-manager-provider-prop --provider-name "Default Key Manager" \
#           --set key-store-type:JKS --hostname $DSHOSTNAME --port "$ADMIN_PORT" --bindDn "cn=Directory Manager" \
#           --bindPassword "$PASSWORD" --trustAll --no-prompt

## displaing the status on logs: it's not needed but it's useful on local env
"$OPENDJ_ROOT"/bin/status --offline

echo "[run.sh] restart OpenDJ"
INSTANCE_ROOT="$OPENDJ_ROOT"/
# instance.loc points DJ at the data/ volume
echo $INSTANCE_ROOT >"$OPENDJ_ROOT"/instance.loc

"$OPENDJ_ROOT"/bin/stop-ds
"$OPENDJ_ROOT"/bin/start-ds --nodetach

