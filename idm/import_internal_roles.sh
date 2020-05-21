#!/bin/bash
#
# A script to provision internal roles in IdAM
#

IDM_USERNAME="openidm-admin"
IDM_PASSWORD="openidm-admin"
IDM_URL="http://localhost:8080"

if [ -f "./jq" ]
then
  JQ_PATH="./jq"
else
  JQ_PATH="jq"
fi

# the order the roles are listed in here is important if you want to set assignable roles.
# format is - name : description : default assignable role (optional)
ROLES=(
  'citizen:Citizen:'
  'solicitor:Solicitor:'
  'IDAM_ADMIN_USER:IdAM Admin User:citizen'
  'IDAM_SUPER_USER:IdAM Super User:IDAM_ADMIN_USER'
  'IDAM_SYSTEM_OWNER:IdAM System Owner:IDAM_SUPER_USER'
  'IDAM_SERVICE_ADMIN:IdAM Service Admin User:'
)

IDM_ROLES_ENDPOINT="$IDM_URL/openidm/managed/role/"
IDM_ASSIGNMENT_ENDPOINT="$IDM_URL/openidm/managed/assignment?_action=create"

function create_role ()  {
  local name=$1
  local description=$2
  local defaultassignableroleid=$3
  local ignore1
  local ignore2
  local assignablesection

  if [ -z $defaultassignableroleid ] || [ $defaultassignableroleid == "null" ]; then
      assignablesection="[]"
  else
      assignablesection="[\"$defaultassignableroleid\"]"
  fi

  id=$(curl -k -s \
            ${IDM_ROLES_ENDPOINT} \
            -H 'Content-Type: application/json' \
            -H 'Accept: application/json' \
            -H "X-OpenIDM-Username: $IDM_USERNAME" \
            -H "X-OpenIDM-Password: $IDM_PASSWORD" \
            -d '{
                "_id": "'"$name"'",
                "name": "'"$name"'",
                "description": "'"$description"'",
                "assignableRoles": '$assignablesection',
                "conflictingRoles": []
            }' | $JQ_PATH -r '._id')

  ignore1=$(curl -k -s \
        ${IDM_ASSIGNMENT_ENDPOINT} \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json' \
        -H "X-OpenIDM-Username: $IDM_USERNAME" \
        -H "X-OpenIDM-Password: $IDM_PASSWORD" \
        -d '{
            "_id": "'"$name"'",
            "name": "'"$name"'",
            "description": "'"$description"'",
            "mapping": "managedUser_systemLdapAccount",
            "attributes":[{"name":"ldapGroups","value":["cn='"$name"',ou=groups,dc=reform,dc=hmcts,dc=net"],"assignmentOperation":"mergeWithTarget","unassignmentOperation":"removeFromTarget"}]
          }')

  ignore2=$(curl -k -s --request PATCH \
        ${IDM_ROLES_ENDPOINT}${name} \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json' \
        -H "X-OpenIDM-Username: $IDM_USERNAME" \
        -H "X-OpenIDM-Password: $IDM_PASSWORD" \
        -d '[{"operation":"add","field":"/assignments/-","value":{"_ref":"managed/assignment/'$name'"}}]')

   echo "$id"
}

function get_role_by_name () {
  local name=$1
  id=$(curl -k -s -X GET \
          "$IDM_ROLES_ENDPOINT?_queryFilter=name%20eq%20'$name'" \
          -H 'Accept: application/json' \
          -H "X-OpenIDM-Username: $IDM_USERNAME" \
          -H "X-OpenIDM-Password: $IDM_PASSWORD" \
          | $JQ_PATH -r '.result[0]._id')

  echo "$id"
}

function update_assignable_roles () {
   role_id=$1
   declare -a assignable_roles_array=("${!2}")
   assignable_roles=$(printf '%s' "${assignable_roles_array[@]}" | $JQ_PATH -R . | $JQ_PATH -s -c .)

   curl -k -s --request PATCH \
          "$IDM_ROLES_ENDPOINT$role_id" \
          -H 'Content-Type: application/json' \
          -H 'Accept: application/json' \
          -H "X-OpenIDM-Username: $IDM_USERNAME" \
          -H "X-OpenIDM-Password: $IDM_PASSWORD" \
          -d '[ { "operation": "replace", "field": "/assignableRoles", "value": '$assignable_roles' } ]'
}

for role in "${ROLES[@]}" ; do
    NAME=${role%%:*}
    SECONDPART=${role#*:}
    DESCRIPTION=${SECONDPART%%:*}
    ASSIGNABLE=${SECONDPART#*:}

    echo "Checking if role $NAME exists..."

    ID=$(get_role_by_name $NAME)
    if [ "$ID" == "null" ]; then
        if [ ! -z "$ASSIGNABLE" ]; then
            assignable_role_id=$(get_role_by_name $ASSIGNABLE)
            if [ -z "$assignable_role_id" ] || [ "$assignable_role_id" == "null" ]; then
                echo "It doesn't. Will create it now. Seeding role '$NAME' with description '$DESCRIPTION', but assignable role '$ASSIGNABLE' was not found ..."
            else
                echo "It doesn't. Will create it now. Seeding role '$NAME' with description '$DESCRIPTION' and assignable role id '$assignable_role_id' ..."
            fi
        else
            assignable_role_id="null"
            echo "It doesn't. Will create it now. Seeding role '$NAME' with description '$DESCRIPTION' ..."
        fi
        ID=$(create_role $NAME "$DESCRIPTION" "$assignable_role_id")
    else
        echo "It's already there. Nothing to do."
    fi

    echo "Role $NAME has id $ID"
    echo ""
done

echo ""

echo "Good-bye."