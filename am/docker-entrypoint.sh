#!/usr/bin/env sh

set -x
DIR=`pwd`


command=$1

echo "Command: $command"

export CONFIGURATION_LDAP="${CONFIGURATION_LDAP:-localhost:1389}"
echo "CONFIGURATION_LDAP = $CONFIGURATION_LDAP"


# Default path to config store directory manager password file. This is mounted by Kubernetes.
DIR_MANAGER_PW_FILE=${DIR_MANAGER_PW_FILE:-/var/run/openam/secrets/dirmanager.pw}
# TODO: manage passwords
PW=`cat $DIR_MANAGER_PW_FILE`
export PASSWORD=${PW:-Pa55word11}
export OPENAM_HOME=${OPENAM_HOME:-/opt/tomcat/openam}

# Wait until the configuration store comes up. This function will not return until it is up.
wait_configstore_up() {
    echo "Waiting for the configuration store to come up daje...."
    sleep 80

    while true 
    do
        test="dc=reform,dc=hmcts,dc=net"
        status=`ldapsearch -w "${PASSWORD}" -H "ldap://${CONFIGURATION_LDAP}:${CONFIGURATION_LDAP_PORT}" -D "cn=Directory Manager" -s base -l 5 -b "$test" > /dev/null 2>&1`
        if [ $? = 0 ];
        then
            echo "Configuration store is up"
            break;
        fi
        sleep 10
        echo -n "."
    done
}

# Test the configstore to see if it contains a configuration. Return 0 if configured.
is_configured() {

    echo "Testing if the configuration store is configured with an AM installation"
    TEST_DN="ou=sunIdentityRepositoryService,ou=services,$BASE_DN"
    r=`ldapsearch -w "${PASSWORD}" -H "ldap://${CONFIGURATION_LDAP}:${CONFIGURATION_LDAP_PORT}" -D "cn=Directory Manager"  -s base -l 20 -b "$TEST_DN"  > /dev/null 2>&1)`
    status=$?
    echo "Is configured exit status is $status"
    return $status
}


bootstrap_openam() {
    wait_configstore_up
    is_configured
    if [ $? = 0 ];
    then
      echo "Configstore is present, just run it!"
    else

      "${CATALINA_HOME}/bin/startup.sh"

      echo "waiting restart of DS..."
      sleep 80

      run_amster_configurator "install"
      run_amster_configurator "import"

      echo "we need to restart now"
      "${CATALINA_HOME}/bin/shutdown.sh"
      sleep 10
    fi

}

run_amster_configurator(){
  cd "$FORGEROCK_HOME"/amster/

  case "$1" in
          "install")
            echo "installation with local amster"
            ./amster amster_install.amster
            sed -r "s/^.*ssh-rsa/ssh-rsa/g" "${OPENAM_HOME}/"amster_rsa.pub >> "${OPENAM_HOME}/"authorized_keys
            ;;
          "import")
          echo "import config"
            ./amster amster_import.amster
            ;;
          "update_cookie")
          echo "update cookie name"
            ./amster amster_update_cookie_name.amster
            ;;
          *)
            echo "if you read this message, there's something wrong...."
            ;;
  esac
}


echo "Starting AM... "
bootstrap_openam

exec "${CATALINA_HOME}/bin/catalina.sh" run

