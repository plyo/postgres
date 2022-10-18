#!/bin/bash

# see https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux

log () {
  echo "[pg_backup_rotated.sh]> $@"
}

log "Running backups..."

function perform_backups()
{
    local suffix=$1
    local db_host=$2
    local db_port=$3

    backup_date=`date +%Y-%m-%d`
    backup_file_path="${BACKUP_DIR}${backup_date}${suffix}".backup
    backup_roles_file_path="${backup_file_path}_roles.out"

    if [[ -e ${backup_file_path} ]]; then
        log "${backup_file_path} already exists, skipping dump"
        return 1
    fi

    log "Dumping custom backup for ${DB_NAME} database to ${backup_file_path}"

    if ! pg_dump -Fc -h "$db_host" -p "$db_port" -U postgres ${DB_NAME} -f ${backup_file_path}.in_progress; then
        log "[ERROR] Failed to produce custom backup database ${DB_NAME}"
    else
        pg_dumpall -r -h "$db_host" -p "$db_port" -U postgres -f ${backup_roles_file_path}.in_progress
        cat ${backup_roles_file_path}.in_progress | grep -v ${IGNORE_DUMP_ROLES} > "${backup_roles_file_path}"
        mv ${backup_file_path}.in_progress ${backup_file_path}
        rm -f ${backup_roles_file_path}.in_progress

        if [[ "${S3_KEY}" != "" ]]; then
          mkdir -p "${S3_BACKUP_MNT_POINT}/$db_host"
          s3_backup_file_path="${S3_BACKUP_MNT_POINT}/$db_host/${backup_date}${suffix}".backup
          log "Copy backup for ${DB_NAME} database to ${s3_backup_file_path}"
          cp "${backup_file_path}" "${s3_backup_file_path}"
        fi
        log "Database backup complete!"
    fi
}

function clean_up() {
    local time_to_keep=$1
    local suffix=$2

    find ${BACKUP_DIR} \
      -maxdepth 1 -mtime +${time_to_keep} \
      -name "*${suffix}*" \
      -exec rm -rf '{}' ';'
    if [[ "${S3_KEY}" != "" ]]; then
      find ${S3_BACKUP_MNT_POINT} \
          -maxdepth 1 -mtime +${time_to_keep} \
          -name "*${suffix}*" \
          -exec rm -rf '{}' ';'
    fi
}

function dump_database()
{
    local db_host=$1
    local db_port=$2

    # MONTHLY BACKUPS

    local day_of_month=`date +%d`
    if [[ ${day_of_month} -eq 1 ]];
    then
        log "Deleting all expired monthly backups"
        local suffix="-${db_host}-${db_port}-monthly"
        local days_to_keep_monthly_backup=`expr $(( ${MONTHS_TO_KEEP_MONTHLY} * 30 ))`
        clean_up ${days_to_keep_monthly_backup} ${suffix}

        log "Dumping monthly backup for ${db_host}:${db_port}"
        perform_backups ${suffix} ${db_host} ${db_port}
    fi

    # WEEKLY BACKUPS

    local backup_time=`date +%H:00`

    local day_of_week=`date +%u` #1-7 (Monday-Sunday)
    if [[ ${day_of_week} = ${DAY_OF_WEEK_TO_KEEP} ]];
    then
        log "Deleting all expired weekly backups"
        local days_to_keep_weekly_backups=`expr $(( (${WEEKS_TO_KEEP_WEEKLY} * 7) + 1 ))`
        local suffix="-${db_host}-${db_port}-weekly"
        clean_up ${days_to_keep_weekly_backups} ${suffix}

        log "Dumping weekly backup for ${db_host}:${db_port}"
        perform_backups ${suffix} ${db_host} ${db_port}
    fi

    # DAILY BACKUPS

    log "Deleting all expired daily backups"
    local suffix="-${db_host}-${db_port}-daily"
    clean_up ${DAYS_TO_KEEP_DAILY} ${suffix}

    log "Dumping daily backup for ${db_host}:${db_port}"
    perform_backups ${suffix} ${db_host} ${db_port}

    # HOURLY BACKUPS

    log "Deleting all expired hourly backups"
    suffix="-${db_host}-${db_port}-hourly"
    clean_up ${DAYS_TO_KEEP_HOURLY} ${suffix}

    log "Dumping hourly backup for ${db_host}:${db_port}"
    perform_backups "-${backup_time}-${db_host}-${db_port}-hourly" ${db_host} ${db_port}
}

db_number=1
eval "db_config=\$DB_CONFIG_${db_number}"
while [[ ${db_config} ]]; do
    if [[ "${db_config}" =~ ^([^:]+):([[:digit:]]+):.*$ ]];
    then
      DB_HOST=${BASH_REMATCH[1]}
      DB_PORT=${BASH_REMATCH[2]}

      dump_database ${DB_HOST} ${DB_PORT}
    else
      log "Wrong db config ${db_config}, should match this format: 'host:port:db:user:password'";
      exit 1;
    fi

    let "db_number += 1"
    eval "db_config=\$DB_CONFIG_${db_number}"
done
