# plyo.postgres-backups
Docker image for PostgreSQL backups service

## How it works

This image should be run with linked [plyo.postgres](https://github.com/plyo/plyo.postgres) image. It contains crontab which run backups periodically. To adjust crontab edit [start.sh](plyo/plyo.postgres-backups/blob/master/files/lib/start.sh). Scripts for rotated backups are from [PostgreSQL wiki](https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux). After backups are ready, their copies are uploaded to Google Drive using [NodeJS API](https://github.com/google/google-api-nodejs-client/). Documentation about [how to start with it](https://developers.google.com/drive/v2/web/quickstart/nodejs) and [API reference](https://developers.google.com/drive/v3/reference/files/create) for REST API which used by node. 

## Usage

### How to run locally

First of all, make sure you have [docker installed](https://docs.docker.com/engine/installation/mac/) and run.

Then you can build an image:
```bash
> docker build -t backups .
```

Before you run it, you need to peek up the name or hash of running image for [plyo.postgres](https://github.com/plyo/plyo.postgres). If it's already run, you can see this info using `docker ps` command.

Run backups:
```bash
docker run -it --link db \
  -e CLIENT_ID=... \
  -e CLIENT_SECRET=... \
  -e ACCESS_TOKEN=... \
  -e REFRESH_TOKEN=... \
  -e EXPIRY_DATE=... \
  --name backups \
  backups
```

If you have different from `db` name of running postgres image, use aliases like this `--link your_postgres_name:db`

As you can see you need to set 5 environment variables. To get them you need a google drive account and enabled API. 

1. Pass only **first** step from here https://developers.google.com/drive/v3/web/quickstart/nodejs
2. `npm install`
3. `node showGoogleDriveEnv.js`

Since you run it, you can see logs to check everything is OK
```bash
docker logs backups
```

### How to deploy

See README.md from [plyo.postgres](https://github.com/plyo/plyo.postgres)
