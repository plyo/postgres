#!/bin/bash

if [ -z "$PLYO_PASS" ]; then
    echo "You must set PLYO_PASS variable with password for plyo DB"
    exit 1
fi

if [ -z "$APP_PASS" ]; then
    echo "You must set APP_PASS variable with password for 'app' user of plyo DB"
    exit 1
fi

echo "Searching existing user";
userExists=`psql --username postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='plyo'"`
if [ -z "$userExists" ]; then
    echo "creating DB and user plyo..."
    createuser plyo
    createdb --owner=plyo plyo
    echo "User and DB creation completed successfully"
fi

echo "Searching for app user";
appUserExists=`psql --username postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='app'"`
if [ -z "$appUserExists" ]; then
    echo "creating user app..."
    createuser app
fi

# add app user to plyo group to set default privileges for new tables
psql --username postgres -d plyo <<-EOSQL
    GRANT app TO plyo;
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app;
    GRANT UPDATE ON ALL SEQUENCES IN SCHEMA public TO app;

    ALTER DEFAULT PRIVILEGES FOR ROLE plyo IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES
    TO app;

    ALTER DEFAULT PRIVILEGES FOR ROLE plyo IN SCHEMA public
    GRANT UPDATE ON SEQUENCES
    TO app;
EOSQL

echo "Installing pgcrypt extension"
psql --username postgres -d plyo -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"

echo "=> Modifying 'plyo' user with a preset password in PostgreSQL"
psql --username postgres -d plyo -c "alter user plyo with password '$PLYO_PASS';"
echo "=> Modifying 'app' user with a preset password in PostgreSQL"
psql --username postgres -d plyo -c "alter user app with password '$APP_PASS';"
echo "=> Done!"
