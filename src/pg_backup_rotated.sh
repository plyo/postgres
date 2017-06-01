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

    FINAL_BACKUP_DIR=${BACKUP_DIR}"`date +\%Y-\%m-\%d`$suffix/"

    if [ -d "$FINAL_BACKUP_DIR" ]; then
        echo "$FINAL_BACKUP_DIR already exists, skipping dump"
        return ${SKIPPING}
    fi

    echo "Making backup directory in $FINAL_BACKUP_DIR"

    if ! mkdir -p ${FINAL_BACKUP_DIR}; then
        echo "Cannot create backup directory in $FINAL_BACKUP_DIR. Go and fix it!" 1>&2
        exit 1;
    fi;

    ###########################
    ###### FULL BACKUPS #######
    ###########################

    echo -e "\n\nPerforming full backups"
    echo -e "--------------------------------------------\n"

    for db in ${INCLUDE_SCHEMA_LIST//,/ }
    do
        echo "Custom backup of $db"
        backup_date=`date +%Y-%m-%d_%H:%M`
        backup_file_name=${FINAL_BACKUP_DIR}"${backup_date}_${db_host}_${db_port}_${db}".backup

        if ! pg_dump -Fc -h "$db_host" -p "$db_port" -U postgres "$db" -f ${backup_file_name}.in_progress; then
            echo "[!!ERROR!!] Failed to produce custom backup database $db"
        else
            mv ${backup_file_name}.in_progress ${backup_file_name}
        fi
    done

    echo -e "\nAll database backups complete!"
}

function dump_database()
{
    local db_host=$1
    local db_port=$2

    # MONTHLY BACKUPS

    DAY_OF_MONTH=`date +%d`

    if [ ${DAY_OF_MONTH} -eq 1 ];
    then
        # Delete all expired monthly directories
        find ${BACKUP_DIR} -maxdepth 1 -name "*-${db_host}-${db_port}-monthly" -exec rm -rf '{}' ';'

        perform_backups "-${db_host}-${db_port}-monthly" ${db_host} ${db_port}

        return 0;
    fi

    # WEEKLY BACKUPS

    DAY_OF_WEEK=`date +%u` #1-7 (Monday-Sunday)
    EXPIRED_DAYS=`expr $(( ($WEEKS_TO_KEEP * 7) + 1 ))`

    if [ ${DAY_OF_WEEK} = ${DAY_OF_WEEK_TO_KEEP} ];
    then
        # Delete all expired weekly directories
        find ${BACKUP_DIR} -maxdepth 1 -mtime +${EXPIRED_DAYS} -name "*-${db_host}-${db_port}-weekly" -exec rm -rf '{}' ';'

        perform_backups "-${db_host}-${db_port}-weekly" ${db_host} ${db_port}
        backups_result=$?
        if [ "$backups_result" -eq ${SKIPPING} ]; then
            perform_backups "-${db_host}-${db_port}-hourly-`date +\%H:\%M`" ${db_host} ${db_port}
        fi

        return 0;
    fi

    # DAILY AND HOURLY BACKUPS

    # Delete daily and hourly backups 7 days old or more
    find ${BACKUP_DIR} -maxdepth 1 -mtime +${DAYS_TO_KEEP} -name "*-${db_host}-${db_port}-daily" -exec rm -rf '{}' ';'
    find ${BACKUP_DIR} -maxdepth 1 -mtime +${DAYS_TO_KEEP} -name "*-${db_host}-${db_port}-hourly-*" -exec rm -rf '{}' ';'

    perform_backups "-${db_host}-${db_port}-daily" ${db_host} ${db_port}
    backups_result=$?
    if [ "$backups_result" -eq ${SKIPPING} ]; then
        perform_backups "-${db_host}-${db_port}-hourly-`date +\%H:\%M`" ${db_host} ${db_port}
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
