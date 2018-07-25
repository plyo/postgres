# Backups

Docker image for PostgreSQL rotated backups. Inspired by scripts for rotated backups from [PostgreSQL wiki](https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux).

## How it works

This image is considered to be run periodically by cron ([rancher cron](https://github.com/SocialEngine/rancher-cron) for example). On every execution it makes as many dumps as specified in environment variables. See docker-compose file for examples. 

## Usage

### How to run locally

```bash
docker-compose up
```

then check your `backups/backups` directory.
