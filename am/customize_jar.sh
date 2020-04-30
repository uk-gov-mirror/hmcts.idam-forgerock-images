#!/usr/bin/env sh

function search-and-replace() {
  sed -i  "s/$1/$2/" "$3" || exit 1
}

mkdir -p ./am/tomcat_conf/build/openam-auth-hotp/ || exit 1

unzip -o -q ./am/tomcat_conf/lib/openam-auth-hotp-6.5.2.2.jar -d ./am/tomcat_conf/build/openam-auth-hotp

AM_YAML_PATH="./cnp-idam-packer/ansible/roles/forgerock_am/defaults/main.yml"

notification_email_2fa_templateId_en=$(cat $AM_YAML_PATH | grep notification_email_2fa_templateId_en: | sed 's/^.*: //')
notification_email_2fa_templateId_cy=$(cat $AM_YAML_PATH | grep notification_email_2fa_templateId_cy: | sed 's/^.*: //')

cp ./am/tomcat_conf/build/openam-auth-hotp/amAuthHOTP.properties ./am/tomcat_conf/build/openam-auth-hotp/amAuthHOTP_cy.properties
search-and-replace "messageSubject=OpenAM One Time Password" "messageSubject=$notification_email_2fa_templateId_en" "./am/tomcat_conf/build/openam-auth-hotp/amAuthHOTP.properties"
search-and-replace "messageSubject=OpenAM One Time Password" "messageSubject=$notification_email_2fa_templateId_cy" "./am/tomcat_conf/build/openam-auth-hotp/amAuthHOTP_cy.properties"

(cd ./am/tomcat_conf/build/openam-auth-hotp/ && zip -r ../openam-auth-hotp-6.5.2.2.jar .)

rm -rf ./am/tomcat_conf/build/openam-auth-hotp