#!/bin/bash

$OPENDJ_ROOT/bin/dsconfig create-backend \
 --backend-name userRoot \
 --set base-dn:$CTS_BASE_DN \
 --set enabled:true \
 --type je \
 --port $ADMIN_PORT \
 --bindDN "$USER" \
 --bindPassword $PASSWORD\
 --trustAll \
 --no-prompt
