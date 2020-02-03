#!/bin/bash

$OPENDJ_ROOT/bin/dsconfig \
 set-access-control-handler-prop \
 --hostname localhost \
 --port $ADMIN_PORT \
 --bindDN "$USER" \
 --bindPassword "$PASSWORD" \
 --no-prompt \
 --trustAll \
 --add 'global-aci:(target = "ldap:///cn=schema")(targetattr = "attributeTypes || objectClasses")(version 3.0; acl "Modify schema"; allow (write) userdn = "ldap:///uid=openam,ou=admins,dc=reform,dc=hmcts,dc=net";)'
