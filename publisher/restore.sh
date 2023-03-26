psql -f /dumps/roles.backup -U postgres
pg_restore /dumps/db.backup -U postgres -d ${DB_NAME}
