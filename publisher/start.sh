#!/usr/bin/env bash
docker login -p=$DOCKERHUB_PASS -u=$DOCKERHUB_LOGIN
docker pull plyo/postgres:9.5.10-1.0.1

docker run --name plyo_postgres -d -e POSTGRES_PASS -e PLYO_PASS -e APP_PASS \
-v $PUBLISHER_DIR/restore.sh:/restore.sh \
-v $DUMPS_DIR:/files \
-p 127.0.0.1:5432:5432 \
plyo/postgres:9.5.10-1.0.1

for i in `seq 1 15`
do
    # if db is started pg_ctl status should return something like 'single-user server is running (PID: 68)'
    case $(docker exec -u postgres plyo_postgres pg_ctl status) in
        *PID* ) break ;;
    esac
    echo -n .
    sleep 1
done

docker exec plyo_postgres mkdir /dumps
backup_date=`date +%Y-%m-%d-%H_00`
backup_file="${backup_date}"-preview-db-5432-hourly.backup
docker exec plyo_postgres cp /files/${backup_file} /dumps/plyo.backup
docker exec plyo_postgres cp /restore.sh /docker-entrypoint-initdb.d/restore.sh

docker commit $(docker ps -f name=plyo_postgres -q) plyo/postgres:publisher
docker push plyo/postgres:publisher

docker kill plyo_postgres
docker rm plyo_postgres
