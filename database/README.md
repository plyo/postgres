# Plyo PostgreSQL Docker Image
Docker image for Plyo database

## Users
This image runs PostgreSQL server, creates a database which name is specified in `DB_NAME` env var and number of users: 
- `postgres` - root for PostgreSQL
- `admin` - your db owner, this user has full access to the created database and can be used for migrations. You can adjust user name with ADMIN_ROLE_NAME env var
- `app` - user which can't modify schema of the db. You can adjust user name with APP_ROLE_NAME env var

To run it locally just use `docker-compose`:

## Extensions
In `EXTENSIONS` env var you can list extensions which will be pre-installed at the moment of first start of the container. See example in `docker-compose.yml`

## Running locally
```bash
$ docker-compose up
```

That's all, you can connect to the running DB using `psql`, [DataGrip](https://www.jetbrains.com/datagrip/) or any other tools.
