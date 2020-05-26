
FROM ubuntu:18.04

WORKDIR /opt
RUN apt-get update && apt-get install -y openjdk-8-jre openjdk-8-jdk unzip && apt-get install vim -y
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV OPENDJ_JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# You can use these options on jdk 8u131 or later. This will set the heap size according to the container size
ENV OPENDJ_JAVA_ARGS -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap

# The default BASE_DN of the directory tree.
ENV BASE_DN dc=reform,dc=hmcts,dc=net
ENV AM_CONFIG_BASE_DN dc=reform,dc=hmcts,dc=net

ENV INSTANCE_ROOT /opt/opendj/data
ENV OPENDJ_ROOT /opt/opendj
ENV SRC /opt/opendj/bootstrap
ENV SECRET_PATH /opt/opendj/secrets/
ENV DIR_MANAGER_PW_FILE /opt/opendj/secrets/dirmanager.pw

ENV LDAP_PORT 1389
ENV LDAPS_PORT 1636
ENV ADMIN_PORT 4444
ENV HTTP_PORT 8080
ENV HTTPS_PORT 8443

ENV LOCKOUT_FAILURE_COUNT 5
ENV PASSWORD_LOCKOUT_DURATION '60 m'
ENV USER "cn=Directory Manager"
ENV DSHOSTNAME $HOSTNAME
ENV BACKEND userRoot
ENV PASSWORD Pa55word11
ENV OPENAM_USERNAME openam
ENV OPENAM_PASSWORD Pa55word11
ENV CFG_SCRIPTS $OPENDJ_ROOT/setup_scripts_cfg
ENV CTS_SCRIPTS $OPENDJ_ROOT/setup_scripts_cts
ENV CTS_BASE_DN dc=reform,dc=hmcts,dc=net
ENV CTS_TOKEN_BASE_DN ou=famrecords,ou=openam-session,ou=tokens,$CTS_BASE_DN
ENV OPENAM_CTS_USERNAME openam

# Use this to directly add the opendj zip file
ADD opendj.zip /home/forgerock/

RUN groupadd -r forgerock && \
    useradd -rmg forgerock forgerock && \
    echo 'forgerock ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

RUN unzip -q /home/forgerock/opendj.zip -d /opt \
    && rm -f /home/forgerock/opendj.zip \
    && mkdir -p "$INSTANCE_ROOT" \
    && mkdir -p "$SECRET_PATH" \
    && chown -R forgerock /opt

# TODO: see how secrets needs to be managed
ADD secrets/ "$SECRET_PATH"/
ADD *.sh /opt/opendj/
ADD bootstrap/cfg_cts_store/setup_scripts_cts /opt/opendj/setup_scripts_cts/
ADD bootstrap/cfg_cts_store/setup_scripts_cfg /opt/opendj/setup_scripts_cfg/
ADD bootstrap/user_store /opt/opendj/user_store/
ADD bootstrap/blacklist.txt $OPENDJ_ROOT/blacklist.txt

WORKDIR /opt/opendj

RUN chown -R forgerock:forgerock /opt/ \
    && chown -R forgerock "$SECRET_PATH"
    #&& keytool -importcert -alias server-cert -file $OPENDJ_ROOT/secrets/server-cert.cert -trustcacerts -keystore $JAVA_HOME/lib/security/cacerts -noprompt -storepass changeit

RUN chmod -R 777 /opt/opendj/setup_scripts_cts
RUN chmod -R 777 /opt/opendj/setup_scripts_cfg
RUN chmod -R 777 /opt/opendj/user_store

USER forgerock

ADD secrets/dirmanager.pw /tmp/monitor.pwd

EXPOSE 1389 1636 4444 8080 8443

CMD ["/opt/opendj/run.sh"]



