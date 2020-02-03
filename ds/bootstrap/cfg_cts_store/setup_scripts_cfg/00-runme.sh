#!/bin/bash

LOG_FILE="/tmp/cfg_setups_scripts.log"

echo  >> "$LOG_FILE"
echo  >> "$LOG_FILE"
echo "Starting CFG scripts... " >> "$LOG_FILE"
date >> "$LOG_FILE"

cd "$CFG_SCRIPTS"

{
echo ./01-cfg-setup.sh
./01-cfg-setup.sh
echo 02-add-config-entries.sh
./02-add-config-entries.sh
echo 03-add-global-aci.sh
./03-add-global-aci.sh
echo 04-cts-add-schema.sh
./04-cts-add-schema.sh
echo 05-opendj-user-schema.sh
./05-opendj-user-schema.sh
echo 06-opendj-config-schema.sh
./06-opendj-config-schema.sh
echo 07-create-backend-indexes.sh
./07-create-backend-indexes.sh
#echo 08-rebuild-indexes.sh
#./08-rebuild-indexes.sh
#echo 09-verify-indexes.sh
#./09-verify-indexes.sh
} >> "$LOG_FILE"

echo "Finished" >> "$LOG_FILE"
date >> "$LOG_FILE"

