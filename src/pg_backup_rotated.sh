#!/bin/bash

# see https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux

echo "Running backups..."

###########################
#### START THE BACKUPS ####
###########################

SKIPPING=1

function perform_backups()
{
    local suffix=$1
    local db_host=$2
    local db_port=$3

    backup_date=`date +%Y-%m-%d`
    backup_file_path="${BACKUP_DIR}${backup_date}${suffix}".backup

    if [ -e "${backup_file_path}" ]; then
        echo "${backup_file_path} already exists, skipping dump"
        return ${SKIPPING}
    fi

    echo -e "\n\nPerforming custom backup for plyo database to ${backup_file_path}"

    if ! pg_dump -Fc -h "$db_host" -p "$db_port" -U postgres plyo -f ${backup_file_path}.in_progress; then
        echo "[!!ERROR!!] Failed to produce custom backup database plyo"
    else
        mv ${backup_file_path}.in_progress ${backup_file_path}
        echo -e "\nDatabase backup complete!"
    fi
}

function dump_database()
{
    local db_host=$1
    local db_port=$2

    # MONTHLY BACKUPS

    local day_of_month=`date +%d`
    if [ ${day_of_month} -eq 1 ];
    then
        # Delete all expired monthly backups
        local suffix="-${db_host}-${db_port}-monthly"
        local days_to_keep_monthly_backup=`expr $(( ${MONTHS_TO_KEEP_MONTHLY} * 30 ))`
        find ${BACKUP_DIR} -maxdepth 1 -mtime +${days_to_keep_monthly_backup} -name "*${suffix}" -exec rm -rf '{}' ';'

        perform_backups ${suffix} ${db_host} ${db_port}

        return 0;
    fi

    # WEEKLY BACKUPS

    local backup_time=`date +%H:%M`

    local day_of_week=`date +%u` #1-7 (Monday-Sunday)
    if [ ${day_of_week} = ${DAY_OF_WEEK_TO_KEEP} ];
    then
        # Delete all expired weekly backups
        local days_to_keep_weekly_backups=`expr $(( (${WEEKS_TO_KEEP_WEEKLY} * 7) + 1 ))`
        local suffix="-${db_host}-${db_port}-weekly"
        find ${BACKUP_DIR} -maxdepth 1 -mtime +${days_to_keep_weekly_backups} -name "*${suffix}" -exec rm -rf '{}' ';'

        perform_backups ${suffix} ${db_host} ${db_port}

        # if weekly backups already exists need to try perform hourly backup
        backups_result=$?
        if [ "$backups_result" -eq ${SKIPPING} ]; then
            perform_backups "-${backup_time}-${db_host}-${db_port}-hourly" ${db_host} ${db_port}
        fi

        return 0;
    fi

    # DAILY AND HOURLY BACKUPS

    # Delete expired daily and hourly backups
    find ${BACKUP_DIR} -maxdepth 1 -mtime +${DAYS_TO_KEEP_DAILY} -name "*-${db_host}-${db_port}-daily" -exec rm -rf '{}' ';'
    find ${BACKUP_DIR} -maxdepth 1 -mtime +${DAYS_TO_KEEP_HOURLY} -name "*-${db_host}-${db_port}-hourly" -exec rm -rf '{}' ';'

    perform_backups "-${db_host}-${db_port}-daily" ${db_host} ${db_port}
    backups_result=$?
    if [ "$backups_result" -eq ${SKIPPING} ]; then
        perform_backups "-${backup_time}-${db_host}-${db_port}-hourly" ${db_host} ${db_port}
    fi
}

db_number=1
eval "db_config=\$DB_CONFIG_${db_number}"
while [ "${db_config}" ]; do
    if [[ "${db_config}" =~ ^([^:]+):([[:digit:]]+):.*$ ]];
    then
      DB_HOST=${BASH_REMATCH[1]}
      DB_PORT=${BASH_REMATCH[2]}

      dump_database ${DB_HOST} ${DB_PORT}
    else
      echo "Wrong db config ${db_config}, should match this format: 'host:port:db:user:password'";
      exit 1;
    fi

    let "db_number += 1"
    eval "db_config=\$DB_CONFIG_${db_number}"
done
