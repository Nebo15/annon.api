#!/bin/bash
set -e

POSTGRES_VERSION=9.6

echo "listen_addresses = '*'" >> /etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf
echo "host all all 0.0.0.0/0 trust" >> /etc/postgresql/${POSTGRES_VERSION}/main/pg_hba.conf

service postgresql stop
service postgresql start ${POSTGRES_VERSION}
