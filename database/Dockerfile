ARG version=13.1

FROM postgres:${version}-alpine as db
COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
HEALTHCHECK --interval=5s --timeout=3s CMD pg_isready -d postgres -U postgres

FROM postgres:$version as test
RUN apt-get update && apt-get install -y make colordiff netcat
WORKDIR /app
COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY . /app
