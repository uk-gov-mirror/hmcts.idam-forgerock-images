#!/usr/bin/env bash

function search-and-replace() {
 perl -p -i -e 's/'"$1"'/'"$2"'/g' $3
}

echo "Copying IDM configuration files.."
IDM_SRC="./cnp-idam-packer/ansible/roles/forgerock_idm"

mkdir -p ./idm/build/script || exit 1
mkdir -p ./idm/build/conf || exit 1
mkdir -p ./idm/build/resolver || exit 1


cp $IDM_SRC/templates/boot.properties.j2 ./idm/build/resolver/boot.properties || exit 1
cp $IDM_SRC/templates/datasource.jdbc-default.json.j2 ./idm/build/conf/datasource.jdbc-default.json || exit 1
cp $IDM_SRC/templates/repo.jdbc-postgresql-managed-user.json.j2 ./idm/build/conf/repo.jdbc.json || exit 1
cp $IDM_SRC/templates/selfservice-registration.json.j2 ./idm/build/conf/selfservice-registration.json || exit 1
cp $IDM_SRC/templates/selfservice-reset.json.j2 ./idm/build/conf/selfservice-reset.json || exit 1
cp $IDM_SRC/templates/sync.json.j2 ./idm/build/conf/sync.json || exit 1
cp $IDM_SRC/templates/authentication.json.j2 ./idm/build/conf/authentication.json || exit 1
cp $IDM_SRC/templates/provisioner.openicf-ldap.json.j2 ./idm/build/conf/provisioner.openicf-ldap.json || exit 1
cp $IDM_SRC/templates/external.email.json.j2 ./idm/build/conf/external.email.json || exit 1
cp $IDM_SRC/templates/ui-configuration.json.j2 ./idm/build/conf/ui-configuration.json || exit 1
cp $IDM_SRC/templates/emailTemplate-welcome.json.j2 ./idm/build/conf/emailTemplate-welcome.json || exit 1
cp $IDM_SRC/templates/managed.json.j2 ./idm/build/conf/managed.json || exit 1
cp $IDM_SRC/templates/schedule-sunset-task.json.j2 ./idm/build/conf/schedule-sunset-task.json || exit 1
cp $IDM_SRC/templates/schedule-reconcile-accounts.json.j2 ./idm/build/conf/schedule-reconcile-accounts.json || exit 1
cp $IDM_SRC/templates/schedule-reconcile-roles.json.j2 ./idm/build/conf/schedule-reconcile-roles.json || exit 1
cp $IDM_SRC/templates/sunset.js.j2 ./idm/build/script/sunset.js || exit 1
cp $IDM_SRC/templates/policy.js.j2 ./idm/build/script/policy.js || exit 1
cp ./cnp-idam-packer/ansible/shared-templates/blacklist.txt.j2 ./idm/build/conf/blacklist.txt || exit 1
cp $IDM_SRC/templates/endpoint-notify.json.j2 ./idm/build/conf/endpoint-notify.json || exit 1
cp $IDM_SRC/templates/script.json.j2 ./idm/build/conf/script.json || exit 1
cp $IDM_SRC/templates/access.js.j2 ./idm/build/script/access.js || exit 1
cp $IDM_SRC/templates/notify.groovy.j2 ./idm/build/script/notify.groovy || exit 1
cp $IDM_SRC/templates/audit.json.j2 ./idm/build/conf/audit.json || exit 1
cp $IDM_SRC/templates/startup.sh.j2 ./idm/build/conf/startup.sh || exit 1

# IDM variables
POSTGRES_HOST="shared-db"
POSTGRES_PORT="5432"
POSTGRES_USER="openidm"
POSTGRES_PASSWORD="Pa55word11"
SELFSERVICE_REGISTRATION_LINK="" ;
SELFSERVICE_TOKEN_EXPIRY="1728000" ;
SELFSERVICE_RESET_LINK="" ;
BASE_DN="dc=reform,dc=hmcts,dc=net";
USERSTORE_HOST="userstore";
USERSTORE_PORT="1389";
DM_PASSWORD="Pa55word11";
EMAIL_HOST="smtp-server";
EMAIL_PORT="1025";
EMAIL_USERNAME="idam\@gmail.com";
EMAIL_PASSWORD="";
WELCOME_EMAIL_ENABLED="false";
IDAM_PATH="\/opt"
KEYSTORE_PASSWORD=changeit
NOTIFY_API_KEY="sidam_sandbox-b7ab8862-25b4-41c9-8311-cb78815f7d2d-1f3ed33e-7fb8-4c42-912f-a8300b78340f"
REGISTRATION_EN_TEMPLATEID="dfbe74e8-cc81-4d1f-ae9a-21baa228bdc8"
REGISTRATION_CY_TEMPLATEID="191f1708-b5fa-4bc3-a8f7-9745bc6056b8"
PWDRESET_EN_TEMPLATEID="a3f18f78-bb9a-47f9-9421-dd4cbf33ddc9"
PWDRESET_CY_TEMPLATEID="f2fa6268-abd3-4702-ba3c-c1add04e3d45"
REREGISTRATION_EN_TEMPLATEID="2a705a73-f02b-4259-bd6d-e2a16b5b3860"
REREGISTRATION_CY_TEMPLATEID="f9b54604-a99d-4c09-b786-2b5a75ab51aa"

# IDM replace placeholders with variables
for file in ./idm/build/conf/*; do
  search-and-replace "{{ psql_host }}" "$POSTGRES_HOST" "$file"
  search-and-replace "{{ psql_port }}" "$POSTGRES_PORT" "$file"
  search-and-replace "{{ openidm_repo_port }}" "$POSTGRES_PORT" "$file"
  search-and-replace "{{ psql_user }}" "$POSTGRES_USER" "$file"
  search-and-replace "{{ psql_passwd }}" "$POSTGRES_PASSWORD" "$file"
  search-and-replace "{{ psql_passwd }}" "$POSTGRES_PASSWORD" "$file"
  search-and-replace "{{selfservice_registration}}" "$SELFSERVICE_REGISTRATION_LINK" "$file"
  search-and-replace "{{ idm_selfservice_registration_tokenExpiry }}" "$SELFSERVICE_TOKEN_EXPIRY" "$file"
  search-and-replace "{{selfservice_reset}}" "$SELFSERVICE_RESET_LINK" "$file"
  search-and-replace "{{idm_selfservice_reset_tokenExpiry}}" "$SELFSERVICE_TOKEN_EXPIRY" "$file"
  search-and-replace "{{ baseDN }}" "$BASE_DN" "$file"
  search-and-replace "forgerock-ds-userstore-2.{{ domainSuffix }}" "$USERSTORE_HOST" "$file"
  search-and-replace "{{ userStorePort }}" "$USERSTORE_PORT" "$file"
  search-and-replace "{{ icf_pword }}" "$DM_PASSWORD" "$file"
  search-and-replace "\?ssl=true" "" "$file"
  search-and-replace "\"ssl\" : true" "\"ssl\" : false" "$file"
  search-and-replace "{{ email_host }}" "$EMAIL_HOST" "$file"
  search-and-replace "{{ email_port }}" "$EMAIL_PORT" "$file"
  search-and-replace "{{ email_username }}" "$EMAIL_USERNAME" "$file"
  search-and-replace "{{ email_pword }}" "$EMAIL_PASSWORD" "$file"
  search-and-replace "{{ welcome_email_enabled\|lower }}" "$WELCOME_EMAIL_ENABLED" "$file"
  search-and-replace "{{ idam_path }}" "$IDAM_PATH" "$file"
  search-and-replace "{{ rootUserPassword }}" "$KEYSTORE_PASSWORD" "$file"
  search-and-replace "{% raw %}" "" "$file"
  search-and-replace "{% endraw %}" "" "$file"
done

  search-and-replace "{% raw %}" "" "./idm/build/script/sunset.js"
  search-and-replace "{% endraw %}" "" "./idm/build/script/sunset.js"
  #TODO change so the notify.api.key property is passed to java rather than replaced here
  search-and-replace "System.properties\[\x27notify.api.key\x27\]" "\"$NOTIFY_API_KEY\"" "./idm/build/script/notify.groovy"
  search-and-replace "{{ registration_en_templateId }}" "$REGISTRATION_EN_TEMPLATEID" "./idm/build/script/notify.groovy"
  search-and-replace "{{ registration_cy_templateId }}" "$REGISTRATION_CY_TEMPLATEID" "./idm/build/script/notify.groovy"
  search-and-replace "{{ pwdReset_en_templateId }}" "$PWDRESET_EN_TEMPLATEID" "./idm/build/script/notify.groovy"
  search-and-replace "{{ pwdReset_cy_templateId }}" "$PWDRESET_CY_TEMPLATEID" "./idm/build/script/notify.groovy"
  search-and-replace "{{ reregistration_en_templateId }}" "$REREGISTRATION_EN_TEMPLATEID" "./idm/build/script/notify.groovy"
  search-and-replace "{{ reregistration_cy_templateId }}" "$REREGISTRATION_CY_TEMPLATEID" "./idm/build/script/notify.groovy"

echo "OK"