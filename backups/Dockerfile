FROM alpine
RUN apk add --update bash postgresql && rm -rf /var/cache/apk/*

VOLUME /backups

ADD src/* /usr/src/app/
RUN chmod 755 /usr/src/app/*.sh

CMD ["/usr/src/app/start.sh"]
