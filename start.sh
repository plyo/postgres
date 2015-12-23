#!/usr/bin/env bash

echo "Saving password for postgres"
echo "db:5432:*:postgres:$POSTGRES_PASS" > /root/.pgpass
chmod 0600 /root/.pgpass

echo "Starting cron with following rules:"
cat /etc/cron.d/crontab
cron
tail -f /var/log/cron.log
