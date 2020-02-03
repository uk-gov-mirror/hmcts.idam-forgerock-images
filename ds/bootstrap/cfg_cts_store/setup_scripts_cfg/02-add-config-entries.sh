#!/bin/bash

echo "add-config-entries.ldif "

$OPENDJ_ROOT/bin/ldapmodify \
 --port $LDAP_PORT \
 --bindDN "$USER" \
 --bindPassword $PASSWORD \
 "$CFG_SCRIPTS/ldif/add-config-entries.ldif"