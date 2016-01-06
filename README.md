# plyo.postgres

Docker image for Plyo database

## What it does

This image runs PostgreSQL and creates database and user for plyo. Use together with
[postgres-backups](https://github.com/plyo/plyo.postgres-backups) on production.

- "plyo" user, db owner - for migrations
- "app" user - for application

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
  -e APP_PASS=password \
  -e PLYO_PASS=password \
  -e POSTGRES_PASS=password \
  --name=db postgres
```

You can see logs for the image using
```bash
docker logs db
```

#### Connecting to the server
That's all, you can connect to postgres using `psql`. To do this, you need Postgres installed locally. Check out [this guide](https://www.codefellows.org/blog/three-battle-tested-ways-to-install-postgresql) for platform-dependent recommendations, but it should be as simple as an `apt-get install postgresql` on Linux, `brew install postgres` on OSX, or a binary download on Windows (make sure it is Postgres >= 9.4).

Once properly installed, connecting to the DB server should be as simple as `psql -h <IP> -U plyo`, where `IP` is the IP of your running docker machine. On Linux (and Windows?) docker exposes ports to `locahost`, so you should be able to just use that. On OSX , you can get the IP of your machine using `(docker-machine ip default)`. Enter `password` when prompted.

Once connected, verify that things are OK with something like `SELECT version();` command. `\q` to quit.

#### Importing data
To use the DB for local development we obviously need some data. We can use a nightly DB dump from production for this, made nightly by the [postgres-backups](https://github.com/plyo/plyo.postgres-backups) image running on Tutum and stored in Plyo Google Drive -> "backups" folder.

Given the correct path to backup image, and granted you have `gunzip` installed, this command should import that dump into the local DB:

`gunzip -c plyo_backup.sql.gz | psql -h <IP> -U postgres -d plyo` which will connect to server as `postgres` user and dump contents into `plyo` db.

We use `postgres` user here instead of Plyo because of permissions needed to install extensions included in the dump.

Now, re-connect to the server and list DBs using `\list` - you should see `plyo` database as first DB. Connect to it using `\connect plyo`, and list all tables using `\dt`. If you see the familiar tables, then you're ready to use this DB for local development! Just make sure you have set `POSTGRES_SERVER` to the IP of your docker machine (this value defaults to `localhost` in our projects).

### How to deploy using tutum

First of all, create two repos. Bind one to this repo and one to [postgres-backups](https://github.com/plyo/plyo.postgres-backups)

Then create node(s) and set `postgres` deployment tag for it(them)

![creating node](http://i.imgur.com/Zu1Ly4S.png)

Then create a stack using [tutum.yml](https://github.com/plyo/plyo.postgres/blob/master/tutum.yml) file from the repo

![stack](http://i.imgur.com/lq5il2i.png)

Do not forget to set environment variables in stack files. See [postgres-backups](https://github.com/plyo/plyo.postgres-backups) README for GoogleDrive API env variables.
