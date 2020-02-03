#!/bin/bash

# Change default for index to 50000
$OPENDJ_ROOT/bin/dsconfig  \
  set-backend-index-prop \
  --hostname localhost \
  --port $ADMIN_PORT \
  --bindDN "$USER" \
  --bindPassword  "$PASSWORD" \
  --backend-name userRoot \
  --index-name objectClass \
  --set index-entry-limit:50000 \
  --no-prompt \
  --trustAll

$OPENDJ_ROOT/bin/dsconfig  \
  set-backend-index-prop \
    --hostname localhost \
    --port $ADMIN_PORT \
    --bindDN "$USER" \
    --bindPassword "$PASSWORD" \
    --backend-name userRoot \
    --index-name frcoretoken \
    --set index-entry-limit:50000 \
    --no-prompt \
    --trustAll
