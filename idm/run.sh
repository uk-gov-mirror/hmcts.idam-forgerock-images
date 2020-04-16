#!/usr/bin/env sh

IDM_JSN='Content-Type: application/json'
IDM_URL=http://${OPENIDM_HOSTNAME}:${OPENIDM_PORT}/openidm
IDM_USR='X-OpenIDM-Username: openidm-admin'
IDM_PWD='X-OpenIDM-Password: openidm-admin'

IDAM_SYSTEM_OWNER_DATA='{"name" : "IDAM-SYSTEM-OWNER","description" : "I am a system owner..."}'
IDAM_ADMIN_USER_DATA='{"name" : "IDAM-ADMIN-USER","description" : "I am a admin user..."}'
IDAM_SUPER_USER_DATA='{"name" : "IDAM-SUPER-USER","description" : "I am a super user..."}'
LETTER_HOLDER_DATA='{"name" : "letter-holder","description" : "I am a letter-holder..."}'
SOLICITOR_DATA='{"name" : "solicitor","description" : "I am a solicitor..."}'
CITIZEN_DATA='{"name" : "citizen","description" : "I am a citizen..."}'

USER_DATA='{"userName":"idamOwner@HMCTS.NET","sn":"Owner","givenName":"System",    "mail": "idamOwner@HMCTS.NET","telephoneNumber": "082082082", "password":"Pa55word11!" }'
USER_ID='666fabc2-ea7d-4f8c-beca-f9cba6483eb7'

adding_default_user(){

  echo "------- starting ping"
  readyToTest=true

  while $readyToTest
  do
      curl -k -sS -H "${IDM_JSN}" -H "${IDM_USR}" -H "${IDM_PWD}" --request GET "${IDM_URL}/info/ping" | grep ACTIVE_READY
      if [ $? = 0 ];
      then
        echo "IDM is up"
        readyToTest=false
        break
      else
        echo "let's wait...."
        sleep 10
      fi
  done


  echo "let s create roles"
  IDAM_SYSTEM_OWNER_ID=$(curl -k -sS -H "${IDM_JSN}" -H "${IDM_USR}" -H "${IDM_PWD}" --request POST --data "${IDAM_SYSTEM_OWNER_DATA}"  "${IDM_URL}/managed/role?_action=create " | jq -r ._id)
  IDAM_ADMIN_USER_ID=$(curl -k -sS -H "${IDM_JSN}" -H "${IDM_USR}" -H "${IDM_PWD}" --request POST --data "${IDAM_ADMIN_USER_DATA}"  "${IDM_URL}/managed/role?_action=create " | jq -r ._id)
  IDAM_SUPER_USER_ID=$(curl -k -sS -H "${IDM_JSN}" -H "${IDM_USR}" -H "${IDM_PWD}" --request POST --data "${IDAM_SUPER_USER_DATA}"  "${IDM_URL}/managed/role?_action=create " | jq -r ._id)
  LETTER_HOLDER_ID=$(curl -k -sS -H "${IDM_JSN}" -H "${IDM_USR}" -H "${IDM_PWD}" --request POST --data "${LETTER_HOLDER_DATA}"  "${IDM_URL}/managed/role?_action=create " | jq -r ._id)
  curl -k -sS -H "${IDM_JSN}" -H "${IDM_USR}" -H "${IDM_PWD}" --request POST --data "${SOLICITOR_DATA}"  "${IDM_URL}/managed/role?_action=create"
  curl -k -sS -H "${IDM_JSN}" -H "${IDM_USR}" -H "${IDM_PWD}" --request POST --data "${CITIZEN_DATA}"  "${IDM_URL}/managed/role?_action=create"
  echo "let s create the user for local test"
  curl -k -sS -H "${IDM_JSN}" -H "${IDM_USR}" -H "${IDM_PWD}" --header "If-None-Match: *" --request PUT --data "${USER_DATA}" "${IDM_URL}/managed/user/${USER_ID}"
  echo "let s add one role"
  USER_ROLE_DATA='[{"operation": "add","field": "/roles/-","value": {"_ref" : "managed/role/'${IDAM_SYSTEM_OWNER_ID}'"} }]'
  curl -k -sS -H "${IDM_JSN}" -H "${IDM_USR}" -H "${IDM_PWD}" --request PATCH --data "${USER_ROLE_DATA}" "${IDM_URL}/managed/user/${USER_ID}"

}

echo "starting idm!"

if [ -z "$(ls -A /opt/openidm/logs)" ]; then
   echo "First installation. let's sleep..."
   sleep 180
   adding_default_user & /opt/openidm/startup.sh --thread
else
   echo "Configuration is there!"
   /opt/openidm/startup.sh --thread
fi





