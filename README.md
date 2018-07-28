# plyo/postgres

This repo contains 3 docker images:

1. [plyo/postgres:database](/database) - PostgreSQL server v10 with 3 pre-configured roles based on official docker postgres image
2. [plyo/postgres:backups](/backups) - Rotated backups which can work with several database instances
3. [plyo/postgres:publisher](/publisher) - Service which can publish your dumps to docker registry. Useful for development and test environments

See all available [tags on Docker Hub](https://hub.docker.com/r/plyo/postgres/tags/) 
