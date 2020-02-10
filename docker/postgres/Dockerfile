FROM postgres:alpine

ENV POSTGRES_USER=openidm
#ENV POSTGRES_PASSWORD=openidm
ENV POSTGRES_PASSWORD=Pa55word11
ENV PGUSER=openidm
ENV POSTGRES_DB=""
ENV PGDATA=/var/lib/postgresql/data/pgdata

EXPOSE 5432

RUN mkdir -p /docker-entrypoint-initdb.d
RUN apk add --no-cache vim

WORKDIR /
USER postgres

ADD sql/*.sql /docker-entrypoint-initdb.d/
ADD *.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
#CMD ["start"]



