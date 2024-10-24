#!/bin/bash

# see https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux
BACKUP_TMP_DIR=${BACKUP_TMP_DIR:-/tmp}

log () {
  echo "[pg_backup_rotated.sh]> $@"
}

log "Running backups..."

function perform_backups()
{
    local suffix=$1
    local db_host=$2
    local db_port=$3
    local db_user=$4

    backup_date=`date +%Y-%m-%d`
    backup_file_path="${BACKUP_DIR}${db_host}/${backup_date}${suffix}".backup
    backup_progress_file_path="${BACKUP_TMP_DIR}${backup_date}${suffix}".backup
    backup_roles_file_path="${backup_file_path}_roles.out"
    backup_progress_roles_file_path="${backup_progress_file_path}_roles.out"

    mkdir -p "$(dirname "${backup_file_path}")"

    if [[ -e ${backup_file_path} ]]; then
        log "${backup_file_path} already exists, skipping dump"
        return 1
    fi

    log "Dumping custom backup for ${DB_NAME} database to ${backup_file_path}"

    if ! pg_dump -Fc -h "$db_host" -p "$db_port" -U "$db_user" ${DB_NAME} -f ${backup_progress_file_path}.in_progress; then
        log "[ERROR] Failed to produce custom backup database ${DB_NAME}"
        exit 1
    else
        # finalize database backup
        mv ${backup_progress_file_path}.in_progress ${backup_file_path}

        # perform backup of database roles
        if [[ "${PERFORM_BACKUP_ROLES}" == "1" ]]; then
          log "Dumping roles backup for ${DB_NAME} database to ${backup_roles_file_path}"
          pg_dumpall -r -h "$db_host" -p "$db_port" -U postgres -f ${backup_progress_roles_file_path}.in_progress
          cat ${backup_progress_roles_file_path}.in_progress | grep -v ${IGNORE_DUMP_ROLES} > "${backup_roles_file_path}"
          rm -f ${backup_progress_roles_file_path}.in_progress
        fi

        # perform copy backup to S3-compatible storage
        if [[ "${S3_KEY}" != "" ]]; then
          mkdir -p "${S3_BACKUP_MNT_POINT}/$db_host"
          s3_backup_file_path="${S3_BACKUP_MNT_POINT}/$db_host"
          log "Copy backup for ${DB_NAME} database to ${s3_backup_file_path}"
          cp "${backup_file_path}" "${s3_backup_file_path}"
          if [[ "${PERFORM_BACKUP_ROLES}" == "1" ]]; then
            cp "${backup_roles_file_path}" "${s3_backup_file_path}"
          fi
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
      find "${S3_BACKUP_MNT_POINT}/$db_host" \
          -maxdepth 1 -mtime +${time_to_keep} \
          -name "*${suffix}*" \
          -exec rm -rf '{}' ';'
    fi
}

function dump_database()
{
    local db_host=$1
    local db_port=$2
    local db_user=$3

    # MONTHLY BACKUPS

    local day_of_month=`date +%d`
    if [[ ${day_of_month} -eq 1 ]];
    then
        log "Deleting all expired monthly backups"
        local suffix="-${db_host}-${db_port}-monthly"
        local days_to_keep_monthly_backup=`expr $(( ${MONTHS_TO_KEEP_MONTHLY} * 30 ))`
        clean_up ${days_to_keep_monthly_backup} ${suffix}

        log "Dumping monthly backup for ${db_host}:${db_port} [from user ${db_user}]"
        perform_backups ${suffix} ${db_host} ${db_port} ${db_user}
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

        log "Dumping weekly backup for ${db_host}:${db_port} [from user ${db_user}]"
        perform_backups ${suffix} ${db_host} ${db_port} ${db_user}
    fi

    # DAILY BACKUPS

    log "Deleting all expired daily backups"
    local suffix="-${db_host}-${db_port}-daily"
    clean_up ${DAYS_TO_KEEP_DAILY} ${suffix}

    log "Dumping daily backup for ${db_host}:${db_port} [from user ${db_user}]"
    perform_backups ${suffix} ${db_host} ${db_port} ${db_user}

    # HOURLY BACKUPS

    log "Deleting all expired hourly backups"
    suffix="-${db_host}-${db_port}-hourly"
    clean_up ${DAYS_TO_KEEP_HOURLY} ${suffix}

    log "Dumping hourly backup for ${db_host}:${db_port} [from user ${db_user}]"
    perform_backups "-${backup_time}-${db_host}-${db_port}-hourly" ${db_host} ${db_port} ${db_user}
}

db_number=1
eval "db_config=\$DB_CONFIG_${db_number}"
while [[ ${db_config} ]]; do
    if [[ "${db_config}" =~ ^([^:]+):([[:digit:]]+):([^:]+):([^:]+).*$ ]];
    then
      DB_HOST=${BASH_REMATCH[1]}
      DB_PORT=${BASH_REMATCH[2]}
      DB_USER=${BASH_REMATCH[4]}

      dump_database ${DB_HOST} ${DB_PORT} ${DB_USER}
    else
      log "Wrong db config ${db_config}, should match this format: 'host:port:db:user:password'";
      exit 1;
    fi

    let "db_number += 1"
    eval "db_config=\$DB_CONFIG_${db_number}"
done
