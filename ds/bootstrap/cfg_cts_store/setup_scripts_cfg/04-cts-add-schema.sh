#!/bin/bash

echo "04 cts schema"
$OPENDJ_ROOT/bin/ldapmodify \
 --port $LDAP_PORT \
 --bindDN "$USER" \
 --bindPassword $PASSWORD \
 "$CFG_SCRIPTS/ldif/cts-add-schema.ldif"