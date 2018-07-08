#!/bin/bash

adminPass=${ADMIN_PASS:-admin}
appPass=${APP_PASS:-app}
dbName=${DB_NAME:-default}
schemaName=${SCHEMA_NAME:-${dbName}}
privateSchemaName=${PRIVATE_SCHEMA_NAME:-${schemaName}_private}

# add app user to admin group to set default privileges for new tables
psql --username postgres <<-EOSQL
    create user admin with password '${adminPass}';
    create database ${dbName} with owner = 'admin';

    \connect ${dbName}
    drop schema public;

    create schema ${schemaName};
    set schema '${schemaName}';
    grant all privileges on schema ${schemaName} to admin;

    create user app with password '${appPass}';
    grant usage on schema ${schemaName} to app;

    grant select, insert, update, delete on all tables in schema ${schemaName} to app;
    grant update on all sequences in schema ${schemaName} to app;

    alter default privileges for role admin in schema ${schemaName}
    grant select, insert, update, delete on tables
    to app;

    alter default privileges for role admin in schema ${schemaName}
    grant update on sequences
    to app;

    create schema ${privateSchemaName};
    create extension pgcrypto schema ${privateSchemaName};
EOSQL

echo "=> Done!"
