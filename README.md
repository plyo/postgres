# plyo.postgres-backups
Docker image for PostgreSQL backups service

## How it works

This image should be run in pair with [plyo.postgres](https://github.com/plyo/plyo.postgres) image. It contains crontab
which run backups periodically. To adjust crontab edit [start.sh](plyo/plyo.postgres-backups/blob/master/files/lib/start.sh).
Scripts for rotated backups are from [PostgreSQL wiki](https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux).
After backups are ready, their copies are uploaded to Google Drive using
[NodeJS API](https://github.com/google/google-api-nodejs-client/). Documentation about
[how to start with it](https://developers.google.com/drive/v2/web/quickstart/nodejs) and
[API reference](https://developers.google.com/drive/v3/reference/files/create) for REST API which used by node.

## Usage

### How to run locally

1. First of all, make sure you have [docker installed](https://docs.docker.com/engine/installation/mac/) and run.

2. Build postgres image from [plyo.postgres](https://github.com/plyo/plyo.postgres)

3. Then run postgres containers:

  ```bash
> docker-compose up -d postgres-1 postgres-2
```

4. Run backups:

  ```bash
docker-compose up backups
```

### Google drive

As you can see you need to set 5 environment variables for google drive. To get them you need a google drive account and
enabled API.

1. Pass only **first** step from here https://developers.google.com/drive/v3/web/quickstart/nodejs
2. `npm install`
3. `node showGoogleDriveEnv.js`

### How to deploy

See [tutum.yml](tutum.yml) and README.md from [plyo.postgres](https://github.com/plyo/plyo.postgres)
