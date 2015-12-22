FROM debian:jessie
MAINTAINER Andrew Balakirev <balakirev.andrey@gmail.com>

#Install PostgreSQL-9.4
RUN apt-get update && \
    apt-get install -y postgresql-9.4 postgresql-contrib pwgen && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Adjust PostgreSQL configuration so that remote connections to the database are possible. 
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.4/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.4/main/postgresql.conf

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME	["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

ADD modify_postgres_pass.sh ./modify_postgres_pass.sh
ADD create_plyo.sh ./create_plyo.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh

EXPOSE 5432
CMD ["/run.sh"]
