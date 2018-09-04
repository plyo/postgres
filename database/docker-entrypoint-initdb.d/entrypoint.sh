#!/bin/bash

adminRole=${ADMIN_ROLE_NAME:-admin}
appRole=${APP_ROLE_NAME:-app}
adminPass=${ADMIN_PASSWORD:-${adminRole}}
appPass=${APP_PASSWORD:-${appRole}}
dbName=${DB_NAME:-default}
schemaName=${SCHEMA_NAME:-${dbName}}
privateSchemaName=${PRIVATE_SCHEMA_NAME:-${schemaName}_private}

creating_extensions_sql=''
for extension in ${EXTENSIONS//,/ }
do
  creating_extensions_sql="${creating_extensions_sql}
    create extension ${extension} schema ${privateSchemaName};"
done

# add app user to admin group to set default privileges for new tables
psql --username postgres <<-EOSQL
    create user ${adminRole} with createrole password '${adminPass}';
    create database ${dbName} with owner = '${adminRole}';

    \connect ${dbName}
    drop schema public;

    create schema ${schemaName};
    set schema '${schemaName}';
    grant all privileges on schema ${schemaName} to ${adminRole} with grant option;

    create user ${appRole} with password '${appPass}';
    grant usage on schema ${schemaName} to ${appRole};

    grant select, insert, update, delete on all tables in schema ${schemaName} to ${appRole};
    grant update on all sequences in schema ${schemaName} to ${appRole};

    alter default privileges for role ${adminRole} in schema ${schemaName}
    grant select, insert, update, delete on tables
    to ${appRole};

    alter default privileges for role ${adminRole} in schema ${schemaName}
    grant update on sequences
    to ${appRole};

    create schema ${privateSchemaName};
    grant all privileges on schema ${privateSchemaName} to ${adminRole} with grant option;

    ${creating_extensions_sql}
EOSQL

echo "=> Done!"
