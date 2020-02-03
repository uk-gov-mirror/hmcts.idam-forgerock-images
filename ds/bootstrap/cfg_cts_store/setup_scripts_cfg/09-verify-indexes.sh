#!/bin/bash

# Note that if you are running OpenDJ 3 and later, you need to stop the server before running this command.
echo "09 verify index.... "
systemctl stop opendj

/opt/opendj/bin/verify-index \
  --baseDN $BASE_DN

# Start OpenDJ back up
systemctl start opendj
