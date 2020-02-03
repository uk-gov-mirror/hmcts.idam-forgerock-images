#!/bin/bash

echo "05 opendj user schema"
$OPENDJ_ROOT/bin/ldapmodify \
 --port $LDAP_PORT \
 --bindDN "$USER" \
 --bindPassword $PASSWORD \
 "$CFG_SCRIPTS/ldif/opendj_user_schema.ldif"