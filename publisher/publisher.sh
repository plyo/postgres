#!/usr/bin/env bash
docker login -p=dkflbvbh1979 -u=balakirevv
docker pull plyo/postgres:9.5.10-1.0.1
export APP_PASS=password
export PLYO_PASS=password
export POSTGRES_PASS=password

docker run --name plyo_postgres -d -e POSTGRES_PASS -e PLYO_PASS -e APP_PASS \
-v /home/vova/projects/docker-dump/dumps:/dumps \
-p 127.0.0.1:5432:5432 \
plyo/postgres:latest

sleep 15

docker exec plyo_postgres pg_restore /dumps/test.backup -h localhost -U postgres -d plyo

docker commit $(docker ps -f name=plyo_postgres -q) plyo/postgres:publisher
docker push plyo/postgres:publisher
docker kill plyo_postgres
docker rm plyo_postgres
