FROM postgres:9.5
ADD docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
