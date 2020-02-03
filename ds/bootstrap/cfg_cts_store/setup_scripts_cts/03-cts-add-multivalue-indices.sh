#!/bin/bash

/opt/opendj/bin/ldapmodify \
  --port $LDAP_PORT \
  --bindDN "$USER" \
  --bindPassword "$PASSWORD" \
  "$CTS_SCRIPTS/ldif/cts-add-multivalue-indices.ldif"
