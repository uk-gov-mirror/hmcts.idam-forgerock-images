#!/bin/bash

#DSHOSTNAME="localhost"
echo "10 prevent anonymous access..."
# Allow unauthenticated access to the DS root entry
$OPENDJ_ROOT/bin/dsconfig set-access-control-handler-prop \
  --add 'global-aci:(target="ldap:///")(targetscope="base")(targetattr="objectClass||namingContexts||supportedAuthPasswordSchemes||supportedControl||supportedExtension||supportedFeatures||supportedLDAPVersion||supportedSASLMechanisms||vendorName||vendorVersion")(version 3.0; acl "User-Visible Root DSE Operational Attributes"; allow (read,search,compare) userdn="ldap:///anyone";)' \
  --hostname "$DSHOSTNAME" \
  --port $ADMIN_PORT \
  --bindDN "$USER" \
  --bindPassword $PASSWORD \
  --trustAll \
  --no-prompt

# Remove the default access to anonymous users
$OPENDJ_ROOT/bin/dsconfig set-access-control-handler-prop \
  --remove 'global-aci:(targetattr!="userPassword||authPassword||debugsearchindex||changes||changeNumber||changeType||changeTime||targetDN||newRDN||newSuperior||deleteOldRDN")(version 3.0; acl "Anonymous read access"; allow (read,search,compare) userdn="ldap:///anyone";)' \
  --hostname "$DSHOSTNAME" \
  --port $ADMIN_PORT \
  --bindDN "$USER" \
  --bindPassword $PASSWORD \
  --trustAll \
  --no-prompt
