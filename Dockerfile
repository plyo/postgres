FROM debian:jessie
MAINTAINER Andrew Balakirev <balakirev.andrey@gmail.com>

# Install cron and client for PostgreSQL
RUN apt-get update && \
    apt-get install -y cron postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ADD crontab /etc/cron.d/crontab
ADD pg_backup.config /pg_backup.config
ADD pg_backup_rotated.sh /pg_backup_rotated.sh
ADD start.sh /start.sh

RUN chmod 755 /*.sh
RUN chmod 0644 /etc/cron.d/crontab
RUN touch /var/log/cron.log

CMD ["/start.sh"]
