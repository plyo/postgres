FROM node:5.8
MAINTAINER Andrew Balakirev <balakirev.andrey@gmail.com>

RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

ENV PG_MAJOR 9.5
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list

# Install cron, client for PostgreSQL, curl for nodejs installation
RUN apt-get update && \
    apt-get install -y \
        cron \
        postgresql-client-$PG_MAJOR \
        curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

VOLUME /backups

ADD package.json /package.json
RUN npm install

ADD files/* /

RUN chmod 755 /*.sh
RUN touch /var/log/cron.log

CMD ["/start.sh"]
