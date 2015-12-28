# plyo.postgres

Docker image for Plyo database

## What it does

This image runs PostgreSQL and creates database and user for plyo.  Use together with [postgres-backups](https://github.com/plyo/plyo.postgres-backups) on production.

## Usage

### How to run locally

First of all, make sure you have [docker installed](https://docs.docker.com/engine/installation/mac/) and run.

Then you can build an image:
```bash
> docker build -t postgres .
```

Then you can run it
```bash
docker run -d -p 5432:5432 \
  -e PLYO_PASS=password \
  -e POSTGRES_PASS=password \
  --name=db postgres
```

You can see logs for the image using
```bash
docker logs db
```

That's all, you can connect to postgres using `psql`

### How to deploy using tutum

First of all, create two repos. Bind one to this repo and one to  [postgres-backups](https://github.com/plyo/plyo.postgres-backups)

Then create node(s) and set `postgres` deployment tag for it(them) 

![creating node](http://i.imgur.com/Zu1Ly4S.png)

Then create a stack using [tutum.yml](https://github.com/plyo/plyo.postgres/blob/master/tutum.yml) file from the repo

![stack](http://i.imgur.com/lq5il2i.png)

Do not forget to set environment variables in stack files. See [postgres-backups](https://github.com/plyo/plyo.postgres-backups) README for GoogleDrvie API env variables.
