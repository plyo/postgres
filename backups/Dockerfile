FROM postgres:9.5

VOLUME /backups

ADD src/* /usr/src/app/
RUN chmod 755 /usr/src/app/*.sh

CMD ["/usr/src/app/start.sh"]
