#!/usr/bin/env bash

echo "Saving password for postgres"
echo "db:5432:*:postgres:$DB_ENV_POSTGRES_PASS" > /root/.pgpass
cat /root/.pgpass
chmod 0600 /root/.pgpass

echo "Preparing crontab"
cat <<EOF > /etc/cron.d/crontab
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
CLIENT_ID=$CLIENT_ID
CLIENT_SECRET=$CLIENT_SECRET
ACCESS_TOKEN=$ACCESS_TOKEN
REFRESH_TOKEN=$REFRESH_TOKEN
EXPIRY_DATE=$EXPIRY_DATE

# Run the backups at 3am each night
0 3 * * * root /pg_backup_rotated.sh -c /pg_backup.config &>> /var/log/cron.log

EOF
chmod 0644 /etc/cron.d/crontab

echo "Starting cron with following rules:"
cat /etc/cron.d/crontab
cron
tail -f /var/log/cron.log
