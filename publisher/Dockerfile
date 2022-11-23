FROM alpine

ENV S3_BACKUP_MNT_POINT /var/s3fs
ENV S3_BUCKET_URL ""

ARG S3FS_VERSION=v1.86
ARG DOCKER_CLI_VERSION="17.06.2-ce"
ENV DOWNLOAD_URL="https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_CLI_VERSION.tgz"

RUN apk --update add fuse alpine-sdk automake autoconf libxml2-dev fuse-dev curl-dev git bash;
RUN git clone https://github.com/s3fs-fuse/s3fs-fuse.git; \
 cd s3fs-fuse; \
 git checkout tags/${S3FS_VERSION}; \
 ./autogen.sh; \
 ./configure --prefix=/usr; \
 make; \
 make install; \
 rm -rf /var/cache/apk/*;

# install docker client
RUN apk --update add curl \
    && mkdir -p /tmp/download \
    && curl -L $DOWNLOAD_URL | tar -xz -C /tmp/download \
    && mv /tmp/download/docker/docker /usr/local/bin/ \
    && rm -rf /tmp/download \
    && apk del curl \
    && rm -rf /var/cache/apk/*

WORKDIR /usr/src/app
COPY ./src/* /usr/src/app/
RUN mkdir -p /usr/src/app/sql
COPY ./sql/sanitize.sql /usr/src/app/sql/sanitize.sql

RUN chmod 755 /usr/src/app/*.sh
CMD ./start.sh
