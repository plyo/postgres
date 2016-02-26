#!/usr/bin/env bash

echo "Saving password for postgres"
echo "db:5432:*:postgres:$DB_ENV_POSTGRES_PASSWORD" > /root/.pgpass
cat /root/.pgpass
chmod 0600 /root/.pgpass

echo "Saving env"
cat <<EOF > /etc/cronenv
export CLIENT_ID=$CLIENT_ID
export CLIENT_SECRET=$CLIENT_SECRET
export ACCESS_TOKEN=$ACCESS_TOKEN
export REFRESH_TOKEN=$REFRESH_TOKEN
export GDRIVE_UPLOAD_DIR=$GDRIVE_UPLOAD_DIR
export EXPIRY_DATE=$EXPIRY_DATE
export BACKUP_USER=$BACKUP_USER
export HOSTNAME=$HOSTNAME
export USERNAME=$USERNAME
export BACKUP_DIR=$BACKUP_DIR
export ENABLE_CUSTOM_BACKUPS=$ENABLE_CUSTOM_BACKUPS
export ENABLE_PLAIN_BACKUPS=$ENABLE_PLAIN_BACKUPS
export DAY_OF_WEEK_TO_KEEP=$DAY_OF_WEEK_TO_KEEP
export DAYS_TO_KEEP=$DAYS_TO_KEEP
export WEEKS_TO_KEEP=$WEEKS_TO_KEEP
export EXCLUDE_SCHEMA_LIST=$EXCLUDE_SCHEMA_LIST

EOF

echo "Preparing crontab"
cat <<EOF > /etc/cron.d/crontab
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

$CRON_PERIOD root /pg_backup_rotated.sh &>> /var/log/cron.log

EOF
chmod 0644 /etc/cron.d/crontab

echo "Starting cron with following rules:"
cat /etc/cron.d/crontab
cron

echo "Cron logs:"
tail -f /var/log/cron.log
