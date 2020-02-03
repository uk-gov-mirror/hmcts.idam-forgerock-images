#!/bin/bash

$OPENDJ_ROOT/bin/dsconfig \
 --port $ADMIN_PORT \
 --bindDN "$USER" \
 --bindPassword "$PASSWORD" \
 --batchFilePath "$CTS_SCRIPTS/ldif/cts-add-indexes.txt" \
 --trustAll \
 --no-prompt
