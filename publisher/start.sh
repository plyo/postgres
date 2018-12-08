#!/usr/bin/env sh
docker login -p=${DOCKERHUB_PASS} -u=${DOCKERHUB_LOGIN} registry.plyo.website
docker pull ${POSTGRES_IMAGE}

docker run --name publishing_db_container -d \
-v ${DUMPS_DIR}:/files \
-w /docker-entrypoint-initdb.d \
${POSTGRES_IMAGE} tail -f /dev/null

docker exec publishing_db_container mkdir /dumps
backup_date=`date +%Y-%m-%d-%H:00`
backup_file=${backup_date}${DUMP_NAME_SUFFIX}
backup_roles_file=${backup_file}_roles.out

if [ $(docker exec publishing_db_container test -e "/files/$backup_file" && echo $?) ];
then
    # we preparing 2 docker images, one contains only needed roles - it's "empty" state of DB
    # another one contains data and can be used by developer and tools running tests on real data
    docker exec publishing_db_container cp /files/${backup_roles_file} /dumps/db_roles.out

    # restore.sh will be executed at the moment of container's start
    cat <<-EORESTORE | (docker exec -i publishing_db_container sh -c "cat > restore.sh")
      psql -f /dumps/db_roles.out -U postgres
EORESTORE

    docker stop publishing_db_container
    docker commit $(docker ps -a -f name=publishing_db_container -q) ${DESTINATION_DOCKER_IMAGE}-roles-only
    docker push ${DESTINATION_DOCKER_IMAGE}-roles-only

    docker start publishing_db_container

    # we need to sanitize sensitive data first
    docker run --name sanitizing_db_container -d --rm -v ${DUMPS_DIR}:/files \
    -e POSTGRES_DB=${DB_NAME} -e POSTGRES_PASSWORD="" ${POSTGRES_IMAGE}
    db_initialized=0
    # waiting 1 min for sanitizing_db_container to be initialized
    for i in `seq 1 60`;
    do
      docker exec sanitizing_db_container psql -U postgres -c "\t" &> /dev/null && db_initialized=1 && break
      echo -n .
      sleep 1
    done

    echo ""

    if [ "$db_initialized" -eq 0 ]
    then
        echo "Sanitizing DB was not initialized after 1 min, stopping..."
        docker kill publishing_db_container
        docker rm publishing_db_container
        docker stop sanitizing_db_container
        exit 0
    fi

    docker exec sanitizing_db_container psql -f /files/${backup_roles_file} -U postgres
    docker exec sanitizing_db_container pg_restore /files/${backup_file} -U postgres -d ${DB_NAME}

    docker cp sql/sanitize.sql sanitizing_db_container:/sanitize.sql
    docker exec sanitizing_db_container psql -f /sanitize.sql -U postgres ${DB_NAME}
    docker exec sanitizing_db_container pg_dump -Fc -U postgres -f /files/${backup_file}.sanitized ${DB_NAME} > /dev/null
    docker stop sanitizing_db_container

    docker exec publishing_db_container cp /files/${backup_file}.sanitized /dumps/db.backup

    cat <<-EORESTORE | (docker exec -i publishing_db_container sh -c "cat >> restore.sh")
      pg_restore /dumps/db.backup -U postgres -d ${DB_NAME}
EORESTORE

    docker commit $(docker ps -a -f name=publishing_db_container -q) ${DESTINATION_DOCKER_IMAGE}
    docker push ${DESTINATION_DOCKER_IMAGE}
else
    docker stop publishing_db_container
    echo file ${backup_file} is not found
fi

docker kill publishing_db_container
docker rm publishing_db_container
