ARG version=13.1

FROM postgres:$version-alpine

ENV S3_BACKUP_MNT_POINT /var/s3fs
ENV S3_BUCKET_URL ""
ENV PERFORM_BACKUP_ROLES "1"

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

VOLUME /backups

RUN mkdir -p "$S3_BACKUP_MNT_POINT"

ADD src/* /usr/src/app/
RUN chmod 755 /usr/src/app/*.sh

CMD ["/usr/src/app/start.sh"]
