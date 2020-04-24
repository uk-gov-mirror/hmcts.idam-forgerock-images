#!/bin/bash
#
# A script to provision internal roles in IdAM
#

AM_USERNAME="amadmin"
AM_PASSWORD="Pa55word11"
AM_URL="http://localhost:8080"
HOST_HEADER=fr-am.local:8181

if [ -f "./jq" ]
then
  JQ_PATH="./jq"
else
  JQ_PATH="jq"
fi

function grant_admin_permissions () {
  local token_id

  [ -f cookies ] && rm cookies

  # Check that we can successfully get a token
  curl -v -sS -c cookies -k -X POST \
    --fail \
    --retry 5 \
    --retry-delay 10 \
    --retry-max-time 10 \
    -H 'Content-Type: application/json' \
    -H "X-OpenAM-Username: $AM_USERNAME" \
    -H "X-OpenAM-Password: $AM_PASSWORD" \
    -H "Host: $HOST_HEADER" \
    -H 'Accept-API-Version: protocol=2.1' \
    -H 'Accept: application/json' \
    "$AM_URL/openam/json/authenticate"

  # Grant permissions to IDAM_SYSTEM_OWNER
  token_id=$(curl -c cookies -k -s -X POST \
              -H 'Content-Type: application/json' \
              -H "X-OpenAM-Username: $AM_USERNAME" \
              -H "X-OpenAM-Password: $AM_PASSWORD" \
              -H "Host: $HOST_HEADER" \
              -H 'Accept-API-Version: protocol=2.1' \
              -H 'Accept: application/json' \
              "$AM_URL/openam/json/authenticate" \
              | $JQ_PATH -r '.tokenId')

  # Wait for users and groups to settle.
  sleep 10
  # Update the Top-Level Realm IDAM_SYSTEM_OWNER Privileges to include 'Read and write access to all realm and policy properties'
  curl --fail -S -k -b cookies -s -X PUT \
          -H 'Accept: application/json' \
          -H 'Accept-API-Version: protocol=2.1,resource=4.0' \
          -H 'Content-Type: application/json' \
          -H 'If-Match: *' \
          -H "Host: $HOST_HEADER" \
          -H 'X-Requested-With: XMLHttpRequest' \
          -d '{
              "username": "IDAM_SYSTEM_OWNER",
              "realm": "/hmcts",
              "universalid": [
                  "id=IDAM_SYSTEM_OWNER,ou=group,o=hmcts,ou=services,dc=reform,dc=hmcts,dc=net"
              ],
              "members": {
                  "uniqueMember": [
                  ]
              },
              "cn": [
                  "IDAM_SYSTEM_OWNER"
              ],
              "privileges": {
                  "RealmAdmin": true,
                  "LogAdmin": false,
                  "LogRead": false,
                  "LogWrite": false,
                  "AgentAdmin": false,
                  "FederationAdmin": false,
                  "RealmReadAccess": false,
                  "PolicyAdmin": false,
                  "EntitlementRestAccess": false,
                  "PrivilegeRestReadAccess": false,
                  "PrivilegeRestAccess": false,
                  "ApplicationReadAccess": false,
                  "ApplicationModifyAccess": false,
                  "ResourceTypeReadAccess": false,
                  "ResourceTypeModifyAccess": false,
                  "ApplicationTypesReadAccess": false,
                  "ConditionTypesReadAccess": false,
                  "SubjectTypesReadAccess": false,
                  "DecisionCombinersReadAccess": false,
                  "SubjectAttributesReadAccess": false,
                  "SessionPropertyModifyAccess": false
              }
          }' \
          $AM_URL/openam/json/realms/root/realms/hmcts/groups/IDAM_SYSTEM_OWNER
}

echo "Granting permissions to system users"
grant_admin_permissions
echo ""
echo ""

echo "Good-bye."