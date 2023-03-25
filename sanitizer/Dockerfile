ARG version=13.1

FROM plyo/postgres:database-7.3.0-$version

ENV S3_BACKUP_MNT_POINT /var/s3fs
ENV S3_BACKUP_MNT_POINT /var/s3fs-sanitized
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
VOLUME /backups
VOLUME /sanitized

WORKDIR /usr/src/app
COPY ./src/* /usr/src/app/
RUN mkdir -p /usr/src/app/sql
COPY ./sql/sanitize.sql /usr/src/app/sql/sanitize.sql

RUN chmod 755 /usr/src/app/*.sh
CMD ./start.sh
