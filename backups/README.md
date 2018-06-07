# plyo.postgres-backups
Docker image for PostgreSQL backups service

## How it works

This image should be run in pair with [plyo.postgres](https://github.com/plyo/plyo.postgres) image. It contains crontab
which run backups periodically. To adjust crontab edit [start.sh](plyo/plyo.postgres-backups/blob/master/files/lib/start.sh).
Scripts for rotated backups are from [PostgreSQL wiki](https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux).

It makes sense to use this container together with cron ([rancher cron](https://github.com/SocialEngine/rancher-cron) for example)
and run the container hourly.

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
