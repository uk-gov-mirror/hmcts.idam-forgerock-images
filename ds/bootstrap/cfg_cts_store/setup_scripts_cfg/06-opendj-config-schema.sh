#!/bin/bash

echo "06 opendj config schema"
$OPENDJ_ROOT/bin/ldapmodify \
 --port $LDAP_PORT \
 --bindDN "$USER" \
 --bindPassword $PASSWORD \
 "$CFG_SCRIPTS/ldif/opendj_config_schema.ldif"