#!/bin/bash
echo "create-backend 2..."
/opt/opendj/bin/dsconfig create-backend \
 --backend-name cfgStore \
 --set base-dn:$BASE_DN \
 --set enabled:true \
 --type je \
 --port $ADMIN_PORT \
 --bindDN "$USER"  \
 --bindPassword $PASSWORD \
 --trustAll \
 --no-prompt