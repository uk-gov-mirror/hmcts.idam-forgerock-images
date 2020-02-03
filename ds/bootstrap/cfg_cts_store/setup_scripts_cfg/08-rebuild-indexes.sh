#!/bin/bash

#DSHOSTNAME="localhost"
echo "rebuild indexes"
$OPENDJ_ROOT/bin/rebuild-index \
 --port $ADMIN_PORT \
 --hostname $DSHOSTNAME \
 --bindDN "$USER" \
 --bindPassword $PASSWORD \
 --baseDN $BASE_DN \
 --rebuildAll \
 --trustAll \
 --start 0
