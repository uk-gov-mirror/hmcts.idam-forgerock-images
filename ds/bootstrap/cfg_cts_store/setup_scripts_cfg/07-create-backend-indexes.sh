#!/bin/bash

#DSHOSTNAME="localhost"
echo "07 create backend index.... do we need it for local?"
$OPENDJ_ROOT/bin/dsconfig create-backend-index \
 --port $ADMIN_PORT \
 --hostname $DSHOSTNAME \
 --bindDN "$USER" \
 --bindPassword $PASSWORD \
 --backend-name userRoot \
 --index-name sunxmlkeyvalue \
 --set index-type:equality \
 --set index-type:substring \
 --trustAll \
 --no-prompt

$OPENDJ_ROOT/bin/dsconfig create-backend-index \
 --port $ADMIN_PORT \
 --hostname $DSHOSTNAME \
 --bindDN "$USER" \
 --bindPassword $PASSWORD \
 --backend-name userRoot \
 --index-name iplanet-am-user-federation-info-key \
 --set index-type:equality \
 --trustAll \
 --no-prompt

$OPENDJ_ROOT/bin/dsconfig create-backend-index \
 --port $ADMIN_PORT \
 --hostname $DSHOSTNAME \
 --bindDN "$USER" \
 --bindPassword $PASSWORD \
 --backend-name userRoot \
 --index-name sun-fm-saml2-nameid-infokey \
 --set index-type:equality \
 --trustAll \
 --no-prompt
