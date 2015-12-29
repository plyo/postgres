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
userExists=`su - postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='plyo'\""`
if [ -z "$userExists" ]; then
    echo "creating DB and user plyo..."
    su - postgres -c "createuser plyo"
    su - postgres -c "createdb --owner=plyo plyo"
    echo "User and DB creation completed successfully"
fi

echo "Searching for app user";
appUserExists=`su - postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='app'\""`
if [ -z "$appUserExists" ]; then
    echo "creating user app..."
    su - postgres -c "createuser app"
    su - postgres -c "psql -U postgres -d plyo -c \"GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app;\""
    su - postgres -c "psql -U postgres -d plyo -c \"GRANT UPDATE ON ALL SEQUENCES IN SCHEMA public TO app;\""
    echo "Privelleges for app user are granted"
fi

echo "Installing pgcrypt extension"
su - postgres -c "psql -U postgres -d plyo -c \"CREATE EXTENSION IF NOT EXISTS pgcrypto;\""

echo "=> Modifying 'plyo' user with a preset password in PostgreSQL"
su - postgres -c "psql -U postgres -d plyo -c \"alter user plyo with password '$PLYO_PASS';\""
echo "=> Modifying 'app' user with a preset password in PostgreSQL"
su - postgres -c "psql -U postgres -d plyo -c \"alter user app with password '$APP_PASS';\""
echo "=> Done!"
