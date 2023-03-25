FROM plyo/postgres:database-7.3.0-14.1

COPY ./sanitized/latest.sanitized /dumps/db.backup
COPY ./restore.sh /docker-entrypoint-initdb.d/
