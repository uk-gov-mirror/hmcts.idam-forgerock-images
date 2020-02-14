FROM ubuntu:18.04

# TODO: manage variables values

WORKDIR /opt

ENV OPENIDM_PORT 8080
ENV OPENIDM_HOSTNAME localhost

COPY IDM-6.5.0.2.zip /tmp/idm.zip
ADD run.sh /

RUN apt-get update && apt-get install unzip -y && apt-get install vim -y && apt-get install openjdk-8-jdk -y && apt-get install curl -y && apt-get install jq -y
RUN unzip -q /tmp/idm.zip && rm -f /tmp/idm.zip

WORKDIR /opt/openidm

RUN rm -fr conf
RUN rm -rf script

COPY conf conf
COPY security security
COPY script script

ENTRYPOINT ["/run.sh" ]
