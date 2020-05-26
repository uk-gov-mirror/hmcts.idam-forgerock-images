#!/usr/bin/env sh
# Run the OpenDJ server
# TODO: look into this...
# We consolidate all of the writable DJ directories to /opt/opendj/data
# This allows us to to mount a data volume on that root which  gives us
# persistence across restarts of OpenDJ.
# For Docker - mount a data volume on /opt/opendj/data
# For Kubernetes mount a PV
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file


cd "$OPENDJ_ROOT"

# If the pod was terminated abnormally the lock file may not have gotten cleaned up.
rm -f "$OPENDJ_ROOT"/locks/server.lock

# TODO: manage passwords
PW=`cat $DIR_MANAGER_PW_FILE`
export PASSWORD=${PW:-Pa55word11}

## this is the "profile" command that esecutes the ldif stored into opendj/template/setup-profiles
## if a different shema is needed, we can use those as a starting point

echo "depending on the DS_TYPE env variable defined in the composer file, a different profile is selected"
case "$DS_TYPE" in
          "cfgAndCts")
            echo "install DS as cts and config store"
            "$OPENDJ_ROOT"/setup directory-server --rootUserDn "cn=Directory Manager" --rootUserPassword "$PASSWORD" --monitorUserPassword "$PASSWORD" \
                  --hostname ds --adminConnectorPort "$ADMIN_PORT" --ldapPort "$LDAP_PORT" --enableStartTls --ldapsPort "$LDAPS_PORT"  --httpPort "$HTTP_PORT" --httpsPort "$HTTPS_PORT" \
                  --profile am-cts:6.5.0 --set am-cts/amCtsAdminPassword:"$PASSWORD" --set am-cts/tokenExpirationPolicy:ds  --set am-cts/baseDn:"ou=tokens,$BASE_DN" \
                  --profile am-config:6.5.0 --set am-config/amConfigAdminPassword:"$PASSWORD"  --set am-config/baseDn:"$BASE_DN" \
                  --acceptLicense
            ;;
          "userstore")
          echo "install userstore"
            "$OPENDJ_ROOT"/setup directory-server --rootUserDn "cn=Directory Manager" --rootUserPassword "$PASSWORD" --monitorUserPassword "$PASSWORD" \
                  --hostname ds --adminConnectorPort "$ADMIN_PORT" --ldapPort "$LDAP_PORT" --enableStartTls --ldapsPort "$LDAPS_PORT"  --httpPort "$HTTP_PORT" --httpsPort "$HTTPS_PORT" \
                  --profile am-identity-store:6.5.0 --set am-identity-store/amIdentityStoreAdminPassword:"$PASSWORD" --set am-identity-store/baseDn:"$BASE_DN" \
                  --acceptLicense
            ;;
          *)
            echo "if you read this message, there's something wrong.... This should not be trigger!!!"
            "$OPENDJ_ROOT"/setup directory-server --rootUserDn "cn=Directory Manager" --rootUserPassword "$PASSWORD" --monitorUserPassword "$PASSWORD" \
                  --hostname ds --adminConnectorPort "$ADMIN_PORT" --ldapPort "$LDAP_PORT" --enableStartTls --ldapsPort "$LDAPS_PORT" --httpPort "$HTTP_PORT" --httpsPort "$HTTPS_PORT" \
                  --profile am-cts:6.5.0 --set am-cts/amCtsAdminPassword:"$PASSWORD" --set am-cts/tokenExpirationPolicy:ds  --set am-cts/baseDn:"ou=famrecords,ou=openam-session,ou=tokens,$BASE_DN" \
                  --profile am-identity-store:6.5.0 --set am-identity-store/amIdentityStoreAdminPassword:"$PASSWORD" --set am-identity-store/baseDn:"$BASE_DN" \
                  --profile am-config:6.5.0 --set am-config/amConfigAdminPassword:"$PASSWORD"  --set am-config/baseDn:"$BASE_DN" \
                  --acceptLicense
            ;;
esac

# echo "https://backstage.forgerock.com/knowledge/kb/book/b56088823 "
"$OPENDJ_ROOT"/bin/dsconfig set-key-manager-provider-prop --provider-name "Default Key Manager" \
           --set key-store-type:JKS --hostname localhost --port "$ADMIN_PORT" --bindDn "cn=Directory Manager" \
           --bindPassword "$PASSWORD" --trustAll --no-prompt

## displaing the status on logs: it's not needed but it's useful on local env
"$OPENDJ_ROOT"/bin/status --offline

echo "restart OpenDJ"
INSTANCE_ROOT="$OPENDJ_ROOT"/
# instance.loc points DJ at the data/ volume
echo $INSTANCE_ROOT >"$OPENDJ_ROOT"/instance.loc

"$OPENDJ_ROOT"/bin/stop-ds
"$OPENDJ_ROOT"/bin/start-ds --nodetach



## if you need to run additional ldif files...

run_ldif_config(){
##If any optional LDIF files are present, load them.
ldif=""$OPENDJ_ROOT"/ldif"

  if [ -d "$ldif" ]; then
      echo "Loading LDIF files in $ldif"
      for file in "${ldif}"/*.ldif;  do
          echo "Loading $file"
          # search + replace all placeholder variables. Naming conventions are from AM.
          sed -e "s/@BASE_DN@/$BASE_DN/"  \
              -e "s/@userStoreRootSuffix@/$BASE_DN/"  \
              -e "s/@DB_NAME@/$DB_NAME/"  \
              -e "s/@SM_CONFIG_ROOT_SUFFIX@/$BASE_DN/"  <${file}  >/tmp/file.ldif

          ./bin/ldapmodify -D "cn=Directory Manager"  --continueOnError -h localhost -p "$LDAP_PORT" -w ${PASSWORD} -f /tmp/file.ldif
        echo "  "
      done
  fi
}
