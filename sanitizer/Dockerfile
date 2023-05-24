ARG version=13.1

FROM plyo/postgres:database-8.0.0-$version

ENV S3_BACKUP_MNT_POINT "/backups"
ENV S3_SANITIZED_BACKUP_MNT_POINT "/sanitized"
ENV S3_BUCKET_URL ""

ARG S3FS_VERSION=v1.86

RUN apk --update add fuse alpine-sdk automake autoconf libxml2-dev fuse-dev curl-dev git bash;
RUN git clone https://github.com/s3fs-fuse/s3fs-fuse.git; \
 cd s3fs-fuse; \
 git checkout tags/${S3FS_VERSION}; \
 ./autogen.sh; \
 ./configure --prefix=/usr; \
 make; \
 make install; \
 rm -rf /var/cache/apk/*;

VOLUME /files
VOLUME $S3_BACKUP_MNT_POINT
VOLUME $S3_SANITIZED_BACKUP_MNT_POINT

WORKDIR /usr/src/app
COPY ./src/* /usr/src/app/
RUN mkdir -p /usr/src/app/sql
COPY ./sql/sanitize.sql /usr/src/app/sql/sanitize.sql

RUN chmod 755 /usr/src/app/*.sh
CMD ./start.sh
