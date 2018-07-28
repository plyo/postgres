# Plyo PostgreSQL Docker Image
This image runs PostgreSQL server. It creates DB instance with name specified in `DB_NAME`. It also creates 2 schemas public and private. You can set names of schemas in env vars. The idea is to use only public schema for application level, it can be automatically introspected by your application.

There are 3 postgres roles created by the image:
- `postgres` - root for PostgreSQL
- `admin` - your db owner, this user has full access to the created database and can be used for migrations
- `app` - user which have access only to public schema, it can't alter schema, only DML allowed for him.

## Running
To run it locally just use `docker-compose`:

```bash
$ docker-compose up
```

That's all, you can connect to the running DB using `psql`, [DataGrip](https://www.jetbrains.com/datagrip/) or any other tools.

## Environment variables
- `POSTGRES_PASSWORD` - password for `postgres` user
- `ADMIN_PASSWORD` - password for `admin` user
- `APP_PASSWORD` - password for `app` user
- `DB_NAME` - name of a creating database, `default` by default
- `SCHEMA_NAME` - public schema name allowed for `app` user, name of DB by default
- `PRIVATE_SCHEMA_NAME` - private schema name, name of public schema by default
