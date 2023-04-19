#!/bin/bash

echo "Saving password for postgres"

# waiting 5 sec to give rancher some time to initialize network, else first database from the list will not be backed up
sleep 5

db_number=1
eval "db_config=\$DB_CONFIG_${db_number}"
while [[ ${db_config} ]]; do
    echo ${db_config} >> /root/.pgpass
    let "db_number += 1"
    eval "db_config=\$DB_CONFIG_${db_number}"
done
chmod 0600 /root/.pgpass

# mount s3 volumes
if [[ "${S3_KEY}" != "" ]]; then
  /usr/src/app/mount-s3.sh
fi

# backup
/usr/src/app/pg_backup_rotated.sh
