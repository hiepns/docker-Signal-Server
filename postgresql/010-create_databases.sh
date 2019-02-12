#!/bin/bash

set -e
set -u

PGUSER="${POSTGRES_USER:-postgres}"

psql -v ON_ERROR_STOP=1 --username "$PGUSER" postgres <<-EOSQL
        CREATE DATABASE accountdb;
        CREATE DATABASE messagedb;
        CREATE DATABASE abusedb;
        GRANT ALL PRIVILEGES ON DATABASE accountdb TO $PGUSER;
        GRANT ALL PRIVILEGES ON DATABASE messagedb TO $PGUSER;
        GRANT ALL PRIVILEGES ON DATABASE abusedb TO $PGUSER;
EOSQL
