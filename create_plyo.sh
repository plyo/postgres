#!/bin/bash

if [ -z "$PLYO_PASS" ]; then
    echo "You must set PLYO_PASS variable with password for plyo DB"
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

echo "Installing pgcrypt extension"
su - postgres -c "psql -U postgres -d plyo -c \"create extension pgcrypto;\""

echo "=> Modifying 'plyo' user with a preset password in PostgreSQL"
su - postgres -c "psql -U postgres -d plyo -c \"alter user plyo with password '$PLYO_PASS';\""
echo "=> Done!"
