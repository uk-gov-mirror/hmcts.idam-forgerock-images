#!/bin/bash

$OPENDJ_ROOT/bin/dsconfig \
 get-access-control-handler-prop \
 --hostname localhost \
 --port $ADMIN_PORT \
 --bindDN "$USER" \
 --bindPassword "$PASSWORD" \
 --no-prompt \
 --trustAll \
 --property global-aci

 # Verify that the following entry is present
 # "(target = "ldap:///cn=schema")(targetattr = "attributeTypes || objectClasses")
 #  (version 3.0; acl "Modify schema"; allow (write) userdn =
 # "ldap:///uid=openam_cts,ou=admins,cn=cts,ou=famrecords,ou=openam-session,ou=tokens";)",
