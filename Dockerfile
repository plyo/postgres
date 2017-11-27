FROM postgres:9.5.10
ADD docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
HEALTHCHECK --interval=5s --timeout=3s CMD pg_isready -d plyo -U postgres
