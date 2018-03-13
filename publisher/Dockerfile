FROM alpine

#RUN apk add --update curl bash \
#  && rm -rf /var/cache/apk/* \
#  && curl -L https://get.docker.com/builds/Linux/x86_64/docker-latest > /usr/bin/docker \
#  && chmod +x /usr/bin/docker

ARG DOCKER_CLI_VERSION="17.06.2-ce"
ENV DOWNLOAD_URL="https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_CLI_VERSION.tgz"

# install docker client
RUN apk --update add curl \
    && mkdir -p /tmp/download \
    && curl -L $DOWNLOAD_URL | tar -xz -C /tmp/download \
    && mv /tmp/download/docker/docker /usr/local/bin/ \
    && rm -rf /tmp/download \
    && apk del curl \
    && rm -rf /var/cache/apk/*

WORKDIR /usr/src/app
COPY . /usr/src/app

RUN chmod 755 publisher.sh
CMD sh publisher.sh
