#!/bin/sh
JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(which javac)")")")/jre"
#explicitly set truststore (for AM to connect to DS over ldaps)
export CATALINA_OPTS="$CATALINA_OPTS \
  -Djavax.net.ssl.trustStore=$JAVA_HOME/lib/security/cacerts \
  -Dcom.sun.identity.configuration.directory=/opt/tomcat/openam"