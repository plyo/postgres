#!/usr/bin/env bash

echo "Saving password for postgres"

db_number=1
db_config_var_name=DB_CONFIG_${db_number};
while [ "${!db_config_var_name}" ]; do
    echo ${!db_config_var_name} >> /root/.pgpass
    export_configs="${export_configs}export ${db_config_var_name}=${!db_config_var_name}\n"
    let "db_number += 1"
    db_config_var_name=DB_CONFIG_${db_number};
done
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
export HOSTNAME=$HOSTNAME
export BACKUP_DIR=$BACKUP_DIR
export DAY_OF_WEEK_TO_KEEP=$DAY_OF_WEEK_TO_KEEP
export DAYS_TO_KEEP=$DAYS_TO_KEEP
export WEEKS_TO_KEEP=$WEEKS_TO_KEEP
export INCLUDE_SCHEMA_LIST=$INCLUDE_SCHEMA_LIST
${export_configs}

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
