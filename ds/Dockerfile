
FROM ubuntu:18.04

WORKDIR /opt
RUN apt-get update && apt-get install -y openjdk-8-jre openjdk-8-jdk unzip
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV OPENDJ_JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# You can use these options on jdk 8u131 or later. This will set the heap size according to the container size
ENV OPENDJ_JAVA_ARGS -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap

ENV SECRET_PATH /var/run/secrets/opendj
ENV DIR_MANAGER_PW_FILE /var/run/secrets/opendj/dirmanager.pw

# The default BASE_DN of the directory tree.
ENV BASE_DN dc=reform,dc=hmcts,dc=net
ENV AM_CONFIG_BASE_DN dc=reform,dc=hmcts,dc=net

ENV INSTANCE_ROOT /opt/opendj/data
ENV OPENDJ_ROOT /opt/opendj
ENV SRC /opt/opendj/bootstrap

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
ENV CFG_SCRIPTS $OPENDJ_ROOT/bootstrap/cfg_cts_store/setup_scripts_cfg
ENV CTS_SCRIPTS $OPENDJ_ROOT/bootstrap/cfg_cts_store/setup_scripts_cts
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
ADD secrets/dirmanager.pw "$SECRET_PATH"/
ADD *.sh /opt/opendj/
ADD bootstrap /opt/opendj/bootstrap

WORKDIR /opt/opendj

RUN chown -R forgerock /opt/ \
    && chown -R forgerock "$SECRET_PATH"

USER forgerock

ADD secrets/dirmanager.pw /tmp/monitor.pwd

EXPOSE 1389 1636 4444 8080 8443

CMD ["/opt/opendj/run.sh"]



