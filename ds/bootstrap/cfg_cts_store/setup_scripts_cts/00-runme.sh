#!/bin/bash

LOG_FILE="/tmp/cts_setups_scripts.log"

echo "Starting CTS scripts... " >> "$LOG_FILE"
date >> "$LOG_FILE"

cd "$CTS_SCRIPTS"

{
#./01-cts-setup.sh already done in the main script
./02-cts-add-multivalue.sh
./03-cts-add-multivalue-indices.sh
./04-cts-indices.sh
./05-cts-user.sh
./06-cts-container.sh
./07-cts-user-aci.sh
./08-verify-cts-user-aci.sh
./09-cts-acis.sh
./10-cts-add-indexes.sh
./11-index_updates-token.sh
./12-rebuild-indexes.sh
} >> $LOG_FILE

echo "Finished" >> "$LOG_FILE"
date >> "$LOG_FILE"
