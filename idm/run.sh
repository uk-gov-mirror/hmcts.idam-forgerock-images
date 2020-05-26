#!/usr/bin/env sh

IDM_JSN='Content-Type: application/json'
IDM_URL=http://${OPENIDM_HOSTNAME}:${OPENIDM_PORT}/openidm
IDM_USR='X-OpenIDM-Username: openidm-admin'
IDM_PWD='X-OpenIDM-Password: openidm-admin'

IDAM_OWNER_USER='{"userName":"idamOwner@HMCTS.NET","sn":"Owner","givenName":"System",    "mail": "idamOwner@HMCTS.NET","telephoneNumber": "082082082", "password":"Pa55word11" }'
IDAM_OWNER_USER_ID='666fabc2-ea7d-4f8c-beca-f9cba6483eb7'

IDAM_TEST_USER='{"userName":"idam@test.localhost","sn":"localhost","givenName":"idam@test",    "mail": "idam@test.localhost@HMCTS.NET","telephoneNumber": "082082082", "password":"Pa55word11" }'
IDAM_TEST_USER_ID='566fabc2-ea7d-4f8c-beca-f9cba6483eb7'

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
  /opt/openidm/import_internal_roles.sh
  echo "lets create users"
  curl -k -sS -H "${IDM_JSN}" -H "${IDM_USR}" -H "${IDM_PWD}" --header "If-None-Match: *" --request PUT --data "${IDAM_OWNER_USER}" "${IDM_URL}/managed/user/${IDAM_OWNER_USER_ID}"
  curl -k -sS -H "${IDM_JSN}" -H "${IDM_USR}" -H "${IDM_PWD}" --header "If-None-Match: *" --request PUT --data "${IDAM_TEST_USER}" "${IDM_URL}/managed/user/${IDAM_TEST_USER_ID}"
  echo "lets add roles to users"
  USER_ROLE_DATA='[{"operation": "add","field": "/roles/-","value": {"_ref" : "managed/role/IDAM_SYSTEM_OWNER"} }]'
  curl -k -sS -H "${IDM_JSN}" -H "${IDM_USR}" -H "${IDM_PWD}" --request PATCH --data "${USER_ROLE_DATA}" "${IDM_URL}/managed/user/${IDAM_OWNER_USER_ID}"
  curl -k -sS -H "${IDM_JSN}" -H "${IDM_USR}" -H "${IDM_PWD}" --request PATCH --data "${USER_ROLE_DATA}" "${IDM_URL}/managed/user/${IDAM_TEST_USER_ID}"

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





