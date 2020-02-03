#!/bin/bash

echo "03 add global aci"
$OPENDJ_ROOT/bin/dsconfig set-access-control-handler-prop \
 --hostname $DSHOSTNAME \
 --port $ADMIN_PORT \
 --add global-aci:'(target = "ldap:///cn=schema")(targetattr = "attributeTypes || objectClasses")(version 3.0; acl "Modify schema"; allow (write) (userdn = "ldap:///uid=openam,ou=admins,dc=reform,dc=hmcts,dc=net");)' \
 --bindDN "$USER" \
 --bindPassword $PASSWORD \
 --trustAll \
 --no-prompt
