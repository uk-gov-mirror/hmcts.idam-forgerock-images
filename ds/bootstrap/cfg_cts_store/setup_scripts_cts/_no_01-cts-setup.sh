#!/bin/bash

set -x
cd /opt/opendj

/opt/opendj/setup \
  directory-server \
  --rootUserDN "{{ bindDN }}" \
  --rootUserPassword "{{ BINDPASSWD }}" \
  --hostname localhost \
  --ldapPort 1389 \
  --ldapsPort 1636 \
  --adminConnectorPort $ADMIN_PORT \
  --baseDN "$CTS_BASE_DN" \
  --acceptLicense \
  --addBaseEntry \
  --keyStorePassword "{{ BINDPASSWD }}" \
  --usePkcs12KeyStore /opt/opendj/keystore

# SET Password encyryption to SSHA5s12
$OPENDJ_ROOT/bin/dsconfig  \
  set-password-policy-prop  \
  --hostname localhost \
  --port $ADMIN_PORT \
  --bindDN "$CTS_BASE_DN" \
  --bindPassword "$PASSWORD" \
  --policy-name "Default Password Policy" \
  --trustAll \
  --set default-password-storage-scheme:"Salted SHA-512" \
  --no-prompt
