# Plyo PostgreSQL Docker Image
Docker image for Plyo database

This image runs PostgreSQL server, creates a database which name is specified in `DB_NAME` env var and number of users: 
- `postgres` - root for PostgreSQL
- `admin` - your db owner, this user has full access to the created database and can be used for migrations
- `app` - user which can't modify schema of the db 

To run it locally just use `docker-compose`:

```bash
$ docker-compose up
```

That's all, you can connect to the running DB using `psql`, [DataGrip](https://www.jetbrains.com/datagrip/) or any other tools.

##### Checking installation with `psql`
To use `psql` client, you need Postgres installed locally. Check out [this guide](https://www.codefellows.org/blog/three-battle-tested-ways-to-install-postgresql) for platform-dependent recommendations, but it should be as simple as an `apt-get install postgresql` on Linux, `brew install postgres` on OSX, or a binary download on Windows (make sure it is Postgres = 9.5).

Once properly installed, connecting to the DB server should be as simple as `psql -h localhost -U admin`. Verify that things are OK with something like `SELECT version();` command. `\q` to quit.

##### Dumps 
Use together with image together with [postgres-backups](https://github.com/plyo/plyo.postgres-backups) on production.