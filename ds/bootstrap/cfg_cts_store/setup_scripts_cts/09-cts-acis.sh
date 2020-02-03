#!/bin/bash

/opt/opendj/bin/ldapmodify \
 --hostname localhost \
 --port $LDAP_PORT \
 --bindDN "$USER" \
 --bindPassword "$PASSWORD" \
 "$CTS_SCRIPTS/ldif/cts-acis.ldif"
