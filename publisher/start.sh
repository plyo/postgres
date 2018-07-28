#!/usr/bin/env bash
docker login -p=${DOCKERHUB_PASS} -u=${DOCKERHUB_LOGIN}
docker pull ${POSTGRES_IMAGE}

docker run --name publishing_db_container -d \
-v ${DUMPS_DIR}:/files \
-w /docker-entrypoint-initdb.d \
${POSTGRES_IMAGE}

docker exec publishing_db_container mkdir /dumps
backup_date=`date +%Y-%m-%d-%H:00`
backup_file=${backup_date}${DUMP_NAME_SUFFIX}

if [ $(docker exec publishing_db_container test -e "/files/$backup_file" && echo $?) ];
then
    docker exec publishing_db_container cp /files/${backup_file} /dumps/db.backup

    # restore.sh will be executed at the moment of container's start
    echo "pg_restore /dumps/db.backup -U postgres -d ${DB_NAME}" | (docker exec -i publishing_db_container sh -c "cat > restore.sh")

    docker stop publishing_db_container
    docker commit $(docker ps -a -f name=publishing_db_container -q) ${DESTINATION_DOCKER_IMAGE}
    docker push ${DESTINATION_DOCKER_IMAGE}
else
    docker stop publishing_db_container
    echo file ${backup_file} is not found
fi

docker kill publishing_db_container
docker rm publishing_db_container
