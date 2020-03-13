#!/usr/bin/env sh
log() {
  echo "[start.sh]> $@"
}

log "Logging in on registry.plyo.website"
docker login -p=${DOCKERHUB_PASS} -u=${DOCKERHUB_LOGIN} registry.plyo.website

log "Pulling fresh postgres image ${POSTGRES_IMAGE}"
docker pull ${POSTGRES_IMAGE}

log "Running publishing container in daemon mode, and start doing nothing"
docker run --name publishing_db_container -d \
  -v ${DUMPS_DIR}:/files \
  -w /docker-entrypoint-initdb.d \
  ${POSTGRES_IMAGE} tail -f /dev/null

log "Creating /dumps dir"
docker exec publishing_db_container mkdir /dumps
backup_date=$(date +%Y-%m-%d-%H:00)
backup_file=${backup_date}${DUMP_NAME_SUFFIX}
backup_roles_file=${backup_file}_roles.out

log "Looking for ${backup_file} inside container"
if [[ $(docker exec publishing_db_container test -e "/files/${backup_file}" && echo $?) ]]; then
  # we preparing 2 docker images, one contains only needed roles - it's "empty" state of DB
  # another one contains data and can be used by developer and tools running tests on real data
  log "Copying a file with dump of roles into publisher container"
  docker exec publishing_db_container cp /files/${backup_roles_file} /dumps/db_roles.out

  # restore.sh will be executed at the moment of container's start
  log "Adding instruction for restoring roles into container startup script"
  cat <<-EORESTORE | (docker exec -i publishing_db_container sh -c "cat > restore.sh")
      psql -f /dumps/db_roles.out -U postgres
EORESTORE

  log "Stopping publishing container to commit roles-only image"
  docker stop publishing_db_container
  docker commit $(docker ps -a -f name=publishing_db_container -q) ${DESTINATION_DOCKER_IMAGE}-roles-only

  log "Pushing a dump with roles to docker registry"
  docker push ${DESTINATION_DOCKER_IMAGE}-roles-only

  log "Running publishing container again to put a dump with actual data"
  docker start publishing_db_container

  # we need to sanitize sensitive data first
  log "Running another postgres docker image for sanitizer"
  docker run --name sanitizing_db_container -d \
    -v ${DUMPS_DIR}:/files \
    -w /docker-entrypoint-initdb.d \
    -e DB_NAME=${DB_NAME} \
    -e APP_ROLE_NAME=${APP_ROLE_NAME} \
    -e ADMIN_ROLE_NAME=${ADMIN_ROLE_NAME} \
    -e SCHEMA_NAME=${SCHEMA_NAME} \
    -e PRIVATE_SCHEMA_NAME=${PRIVATE_SCHEMA_NAME} \
    ${POSTGRES_IMAGE}

  db_initialized=0
  log "Waiting 1 min for sanitizer to be initialized"
  for i in $(seq 1 60); do
    docker exec sanitizing_db_container nc -z localhost 5432 && db_initialized=1 && break
    echo -n .
    sleep 1
  done

  echo ""

  if [[ "$db_initialized" -eq 0 ]]; then
    log "Sanitizing DB was not initialized after 1 min, stopping..."
    docker kill publishing_db_container
    docker rm publishing_db_container
    docker stop sanitizing_db_container
    exit 0
  fi

  log "Restoring dumps to sanitizer container"
  docker exec sanitizing_db_container psql -f /files/${backup_roles_file} -U postgres
  docker exec sanitizing_db_container pg_restore /files/${backup_file} -U postgres -d ${DB_NAME}

  log "Running sanitizing script inside the container"
  docker cp sql/sanitize.sql sanitizing_db_container:/sanitize.sql
  docker exec sanitizing_db_container psql -f /sanitize.sql -U postgres ${DB_NAME}

  log "Making sanitized dump"
  docker exec sanitizing_db_container pg_dump -Fc -U postgres -f /files/${backup_file}.sanitized -d ${DB_NAME} >/dev/null

  log "Stopping sanitizer"
  docker stop sanitizing_db_container

  log "Copy sanitized dump into publisher and adding instruction to restore it into startup script"
  docker exec publishing_db_container cp /files/${backup_file}.sanitized /dumps/db.backup
  cat <<-EORESTORE | (docker exec -i publishing_db_container sh -c "cat >> restore.sh")
      pg_restore /dumps/db.backup -U postgres -d ${DB_NAME}
EORESTORE

  log "Stopping publisher to commit a new image and push it to docker registry"
  docker stop publishing_db_container
  docker commit $(docker ps -a -f name=publishing_db_container -q) ${DESTINATION_DOCKER_IMAGE}
  docker push ${DESTINATION_DOCKER_IMAGE}
  docker commit $(docker ps -a -f name=sanitizing_db_container -q) ${DESTINATION_DOCKER_IMAGE}-s
  docker push ${DESTINATION_DOCKER_IMAGE}-s
else
  log "File ${backup_file} is not found, stopping publishing container"
  docker stop publishing_db_container
  docker stop sanitizing_db_container
fi

log "Trying to kill publisher in case it was not stopped"
docker kill publishing_db_container
docker rm publishing_db_container
docker kill sanitizing_db_container
docker rm sanitizing_db_container
