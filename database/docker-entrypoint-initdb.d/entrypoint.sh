#!/bin/bash

adminPass=${ADMIN_PASS:-admin}
appPass=${APP_PASS:-app}
dbName=${DB_NAME:-default}

# add app user to admin group to set default privileges for new tables
psql --username postgres <<-EOSQL
    create user admin with password '${adminPass}';
    create database ${dbName} with owner = 'admin';
    create user app with password '${appPass}' in group admin;

    revoke all on schema public from public;
    grant select, insert, update, delete on all tables in schema public to app;
    grant update on all sequences in schema public to app;

    alter default privileges for role admin in schema public
    grant select, insert, update, delete on tables
    to app;

    alter default privileges for role admin in schema public
    grant update on sequences
    to app;

    create extension pgcrypto;
EOSQL

echo "=> Done!"
