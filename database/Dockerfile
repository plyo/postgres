FROM postgres:13.1 as db
COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
HEALTHCHECK --interval=5s --timeout=3s CMD pg_isready -d postgres -U postgres

FROM postgres:13.1 as test
RUN apt-get update && apt-get install -y make colordiff netcat
WORKDIR /app
COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY . /app
