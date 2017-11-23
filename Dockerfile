FROM postgres:9.5

# Install nc for healthchecking
RUN apt-get update && apt-get install -y netcat

ADD docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
HEALTHCHECK --interval=5s --timeout=3s CMD nc -z localhost 5432
