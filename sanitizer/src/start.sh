#!/usr/bin/env sh
log () {
  echo "[start.sh]> $@"
}

# mount s3 volumes
if [[ "${S3_KEY}" != "" ]]; then
  /usr/src/app/mount-s3.sh
fi

echo "Looking for the latest backup file"
backup_folder="${S3_BACKUP_MNT_POINT}/$DB_HOST"
sanitized_folder="${S3_SANITIZED_BACKUP_MNT_POINT}/$DB_HOST"
latest=$(ls -t "$backup_folder"/* | head -1)
if [[ "${latest:(-10)}" == "_roles.out" ]]; then
  latest="${latest::-10}"
fi
echo "Found ${latest} backup file"

backup_file=$latest
backup_roles_file=${backup_file}_roles.out

echo "starting postgres..."
rm -rf "${PGDATA}"
/usr/local/bin/docker-entrypoint.sh postgres &

until pg_isready -U postgres -h 0.0.0.0 -p 5432 ; do echo "waiting for postgres to start" && sleep 5 ; done

log "Restoring..."
if [[ -f "${backup_roles_file}" ]]; then
  filename=$(basename -- "$backup_roles_file")
  if [[ ! -f "/files/${filename}" ]]; then
    log "Copy from s3 to /files/${filename}"
    cp "${backup_roles_file}" "/files/${filename}"
  fi
  log "Restoring '/files/${filename}'..."
  psql -f "${backup_roles_file}" -U postgres
  status=$?
  if [ "$status" != "0" ];
  then
    echo "Cannot restore roles file"
    exit 1
  fi
fi

if [[ -f "${ROLES_FILE_PATH}" ]]; then
  log "Restoring '${ROLES_FILE_PATH}'..."
  psql -f "${backup_roles_file}" -U postgres
  status=$?
  if [ "$status" != "0" ];
  then
    echo "Cannot restore roles file"
    exit 1
  fi
fi

filename=$(basename -- "$backup_file")
if [[ ! -f "/files/${filename}" ]]; then
  log "Copy from s3 to /files/${filename}"
  cp "${backup_file}" "/files/${filename}"
fi
log "Restoring '${backup_file}'..."
log "pg_restore /files/${filename}"
pg_restore "/files/${filename}" -U postgres -d ${DB_NAME}
status=$?
if [ "$status" != "0" ];
then
  echo "Cannot restore backup file"
  exit 1
fi

log "Running sanitizing script..."
psql -f sql/sanitize.sql -U postgres ${DB_NAME}
status=$?
if [ "$status" != "0" ];
then
  echo "Cannot process sanitizing..."
  exit 1
fi

log "Making sanitized dump..."
sanitised_file="${filename}.sanitized"
pg_dump -Fc -U postgres -f "/files/${sanitised_file}" -d ${DB_NAME} > /dev/null
status=$?
if [ "$status" != "0" ];
then
  echo "Cannot make sanitized dump..."
  exit 1
fi

log "Copy backup for ${DB_NAME} database to ${sanitized_folder}"
mkdir -p "$sanitized_folder"
cp "/files/${sanitised_file}" "${sanitized_folder}/${sanitised_file}"
if [[ -f "${sanitized_folder}/latest.sanitized" ]]; then
  rm -f "${sanitized_folder}/latest.sanitized"
fi
mv "${sanitized_folder}/${sanitised_file}" "${sanitized_folder}/latest.sanitized"

if [[ -f "$backup_roles_file" ]]; then
    filename=$(basename -- "$backup_roles_file")
    cp "${backup_roles_file}" "${sanitized_folder}/latest_roles.out"
fi

log "Finished"
