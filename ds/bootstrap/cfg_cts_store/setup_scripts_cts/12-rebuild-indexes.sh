#!/bin/bash


systemctl stop opendj

$OPENDJ_ROOT/bin/rebuild-index \
  --baseDN "$CTS_BASE_DN" \
  --rebuildAll \
  --offline

$OPENDJ_ROOT/bin/verify-index \
  --baseDN "$CTS_BASE_DN"

systemctl start opendj
