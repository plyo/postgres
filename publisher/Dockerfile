FROM plyo/postgres:database-7.3.0-13.1

COPY ./sanitized/latest.sanitized /dumps/db.backup
COPY ./sanitized/latest_roles.out /dumps/roles.backup
COPY ./restore.sh /docker-entrypoint-initdb.d/
