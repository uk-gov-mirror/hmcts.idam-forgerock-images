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
ldif=""$OPENDJ_ROOT"/bootstrap/$1"

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
  --set dictionary-file:bootstrap/blacklist.txt \
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
      echo "Loading LDIF files in $ldif"
      for file in "${ldif}"/*.ldif;  do
          echo "$USER Loading $file"
          # search + replace all placeholder variables. Naming conventions are from AM.
          sed -e "s/@BASE_DN@/$BASE_DN/" <${file}  >/tmp/file.ldif

          "$OPENDJ_ROOT"/bin/ldapmodify --bindDN "$USER"  --continueOnError -h $DSHOSTNAME -p "$LDAP_PORT" -w ${PASSWORD} --fileName /tmp/file.ldif
        echo "  "
      done
  fi
}

update_env_variable(){

  cd $CFG_SCRIPTS/ldif
  grep -rl BASE_DN . | xargs sed -i'' "s/BASE_DN/$BASE_DN/"
  grep -rl OPENAM_USERNAME . | xargs sed -i'' "s/OPENAM_USERNAME/$OPENAM_USERNAME/"
  grep -rl OPENAM_PASSWORD . | xargs sed -i'' "s/OPENAM_PASSWORD/$OPENAM_PASSWORD/"

  cd $CTS_SCRIPTS/ldif
  grep -rl CTS_BASE_DN . | xargs sed -i'' "s/CTS_BASE_DN/$CTS_BASE_DN/"
  grep -rl OPENAM_CTS_USERNAME . | xargs sed -i'' "s/OPENAM_CTS_USERNAME/$OPENAM_CTS_USERNAME/"
  grep -rl OPENAM_PASSWORD . | xargs sed -i'' "s/OPENAM_PASSWORD/$OPENAM_PASSWORD/"
  grep -rl CTS_TOKEN_BASE_DN . | xargs sed -i'' "s/CTS_TOKEN_BASE_DN/$CTS_TOKEN_BASE_DN/"

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

  update_env_variable

  cd $CFG_SCRIPTS

  echo "try to run CFG 00-runme.sh script"
  ./00-runme.sh

  cd $CTS_SCRIPTS
  echo "try to run CTS 00-runme.sh script"
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



echo "depending on the DS_TYPE env variable defined in the composer file, a different profile is selected"
case "$DS_TYPE" in
          "userstore")
            echo "install DS as userStore and config store"
            run_userstore_config user_store
            ;;
          "cfgAndCts")
            echo "install Config store and CTS"
            run_ldif_cfg_cts
            ;;
          *)
            echo "if you read this message, there's something wrong.... This should not be trigger!!!"
            ;;
esac


## echo "https://backstage.forgerock.com/knowledge/kb/book/b56088823 "
#"$OPENDJ_ROOT"/bin/dsconfig set-key-manager-provider-prop --provider-name "Default Key Manager" \
#           --set key-store-type:JKS --hostname $DSHOSTNAME --port "$ADMIN_PORT" --bindDn "cn=Directory Manager" \
#           --bindPassword "$PASSWORD" --trustAll --no-prompt

## displaing the status on logs: it's not needed but it's useful on local env
"$OPENDJ_ROOT"/bin/status --offline

echo "restart OpenDJ"
INSTANCE_ROOT="$OPENDJ_ROOT"/
# instance.loc points DJ at the data/ volume
echo $INSTANCE_ROOT >"$OPENDJ_ROOT"/instance.loc

"$OPENDJ_ROOT"/bin/stop-ds
"$OPENDJ_ROOT"/bin/start-ds --nodetach

