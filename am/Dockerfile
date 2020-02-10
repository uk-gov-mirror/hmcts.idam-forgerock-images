# AM Dockerfile
FROM tomcat:8.5.21-jre8-alpine

ENV CATALINA_OPTS -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap \
  -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true \
  -Dcom.sun.identity.util.debug.provider=com.sun.identity.shared.debug.impl.StdOutDebugProvider \
  -Dcom.sun.identity.shared.debug.file.format=\"%PREFIX% %MSG%\\n%STACKTRACE%\"
#  if you need debug level
#  -Dcom.iplanet.services.debug.level=debug

ENV FORGEROCK_HOME /opt/tomcat
ENV OPENAM_HOME /opt/tomcat/openam
ENV DIR_MANAGER_PW_FILE /var/run/openam/secrets/dirmanager.pw

ENV LDAP_PROTOCOL LDAP
ENV CONFIGURATION_LDAP cfgAndCts
ENV CONFIGURATION_LDAP_PORT 1389
ENV OPENAM_PORT 8443
ENV OPENAM_HOSTNAME fr-am.local
ENV BASE_DN dc=reform,dc=hmcts,dc=net
# TODO: we need to chenge this
ENV DEFAULT_PASSWORD Pa55word11
ENV DEDFAULT_LDAP_USER cn=Directory Manager

# TODO: for local environment all the varibles defined by ansible will be defined in the Dockerfile. This should be changed...
ENV AMSTER_VERSION 6.5.2.2
ENV EXT_HOSTNAME fr-am
ENV ANSIBLE_HOSTNAME fr-am
ENV DOMAINSUFFIX local
ENV AM_HTTP_PORT 8443
ENV HTTP_STRING http:
ENV FR_APP openam
ENV USER_STORE_HOST userstore
ENV CFG_STORE_HOST cfgAndCts
ENV CTS_CFG_HOSTS cfgAndCts
ENV USER_STORE_PORT 1389
ENV CFG_STORE_PORT 1389
ENV CTS_PORT 1389
ENV ROOT_USER_DN cn=Directory Manager
ENV ROOT_USER_PASSWORD Pa55word11
ENV CTS_TOKEN_BASEDN ou=tokens,dc=reform,dc=hmcts,dc=net
#ENV CTS_TOKEN_BASEDN ou=famrecords,ou=openam-session,ou=tokens,dc=reform,dc=hmcts,dc=net
ENV PROJECT hmcts
ENV OPENAM_CTS_PASSWORD Pa55word11
#ENV OPENAM_CTS_USERNAME_UID uid=am-config,ou=admins,ou=tokens,dc=reform,dc=hmcts,dc=net
ENV OPENAM_CTS_USERNAME_UID cn=Directory Manager
#ENV OPENAM_CTS_USERNAME_UID uid=openam,ou=admins,dc=reform,dc=hmcts,dc=net
ENV LDAPS_PORT_CTS 1636
ENV AM_BOOTSTRAP_FILE /opt/tomcat/.openamcfg/AMConfig_opt_tomcat_webapps_openam
ENV OPENAM_DIR /opt/tomcat/openam
ENV WEB_APP "http://fr-am.local"
ENV DEFAULT_KEYSTORE_TYPE JCEKS
ENV CERTIFICATE_ALIAS_NAME server-cert
ENV AM_COOKIE_NAME Idam.Session
#ENV AM_COOKIE_NAME iPlanetDirectoryPro
ENV PWD_ENC_KEY Y3pQSnFUTG1pTFMza2R6Y1FNNTdkeUxNcnVQdEJUZU4=
ENV OAUTH_2CLIENT_CONFIG_PWD password

ADD openam_conf/openam.war  /tmp/openam.war
ADD openam_conf/amster.zip /tmp/amster.zip


RUN mkdir -p /opt/tomcat && chmod -R 777 /opt/tomcat && mv /usr/local/tomcat /opt/tomcat

RUN cp -R /opt/tomcat/tomcat/* /opt/tomcat

ENV CATALINA_HOME=/opt/tomcat
ENV CATALINA_BASE=/opt/tomcat

# openldap-clients is needed to test for the configuration store.
RUN apk add --no-cache su-exec unzip curl bash openldap-clients \
  && rm -fr /usr/local/tomcat/webapps/* \
  && unzip -q /tmp/openam.war -d  "$CATALINA_HOME"/webapps/openam \
  && rm /tmp/openam.war \
  && adduser -s /bin/bash -h "$FORGEROCK_HOME" -u 11111 -D forgerock \
  && mkdir -p "$OPENAM_HOME" \
  && mkdir -p "$FORGEROCK_HOME"/.openamcfg \
  && unzip -q /tmp/amster.zip -d "$FORGEROCK_HOME"/amster/ \
  && echo "$OPENAM_HOME" >  "$FORGEROCK_HOME"/.openamcfg/AMConfig_usr_local_tomcat_webapps_openam_  \
  && chmod -R 777 "$CATALINA_HOME" \
  && chmod -R 777  "$FORGEROCK_HOME"

#RUN groupadd tomcat
RUN addgroup tomcatusers && adduser -D tomcat -h "$CATALINA_HOME" && adduser tomcat tomcatusers
RUN chown -R tomcat:tomcat /opt/tomcat

# Settings for Tomcat
ADD tomcat_conf/server.xml "$CATALINA_HOME"/conf/server.xml
ADD tomcat_conf/context.xml "$CATALINA_HOME"/conf/context.xml
ADD tomcat_conf/tomcatcert.jceks "$CATALINA_HOME"/.keystore


ADD openam_conf/*.amster "$FORGEROCK_HOME"/amster/
#ADD openam_conf/config_files.ansiblePacker/ "$FORGEROCK_HOME"/amster/config_files/
ADD openam_conf/config_files/ "$FORGEROCK_HOME"/amster/config_files/

# Path to optional script to customize the AM web app. Use this script hook to copy in images, web.xml, etc.
ENV CUSTOMIZE_AM /opt/tomcat/customize-am.sh

ADD *.sh $FORGEROCK_HOME/
ADD secrets /var/run/openam/secrets/

## TODO change to use forgerock user
RUN chown -R tomcat:tomcat $FORGEROCK_HOME/
RUN chown -R tomcat:tomcat /var/run/openam/
RUN chmod -R 777 $FORGEROCK_HOME/ && chmod -R 777 /var/run/openam/

#USER forgerock
USER tomcat
WORKDIR /opt/tomcat

ENTRYPOINT ["/opt/tomcat/docker-entrypoint.sh"]

CMD ["run"]
# CMD tail -f /dev/null