#!/usr/bin/env bash
docker login -p=$DOCKERHUB_PASS -u=$DOCKERHUB_LOGIN
docker pull plyo/postgres:9.5.10-1.0.1

docker run --name plyo_postgres -d -e POSTGRES_PASS -e PLYO_PASS -e APP_PASS \
-v $DUMPS_DIR:/files \
-w /docker-entrypoint-initdb.d \
plyo/postgres:9.5.10-1.0.1

docker exec plyo_postgres mkdir /dumps
backup_date=`date +%Y-%m-%d-%H:00`
backup_file="${backup_date}"-preview-db-5432-hourly.backup

if [ $(docker exec plyo_postgres test -e "/files/$backup_file" && echo $?) ];
then
    docker exec plyo_postgres cp /files/${backup_file} /dumps/plyo.backup
#    restore.sh will be executed at the moment of container's start
    (docker exec -i plyo_postgres sh -c "cat > restore.sh") < restore.sh

    docker commit $(docker ps -f name=plyo_postgres -q) plyo/postgres:data
    docker push plyo/postgres:data
else
    echo file "${backup_file}" is not found
fi

docker kill plyo_postgres
docker rm plyo_postgres
