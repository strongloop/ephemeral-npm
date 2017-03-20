FROM alpine:3.4
MAINTAINER Ryan Graham <rmg@ca.ibm.com>

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 4.4.5

RUN apk add --no-cache \
        libstdc++ \
    && apk add --no-cache --virtual .build-deps \
        binutils-gold \
        curl \
        g++ \
        gcc \
        gnupg \
        libgcc \
        linux-headers \
        make \
        paxctl \
        python \
        tar \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.gz" \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION.tar.gz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xf "node-v$NODE_VERSION.tar.gz" \
    && cd "node-v$NODE_VERSION" \
    && ./configure --fully-static --with-intl=none \
    && make -j2 V= \
    && make install \
    && cd .. \
    && rm -Rf "node-v$NODE_VERSION" \
    && rm "node-v$NODE_VERSION.tar.gz" SHASUMS256.txt.asc SHASUMS256.txt \
    && npm install --no-spin -g sinopia \
    && npm uninstall --no-spin -g npm \
    && apk del .build-deps \
    && rm -rf ~/.npm* /tmp/npm* /usr/local/lib/node_modules/npm ~/.node* /var/cache/apk/* /usr/local/include/node \
    && adduser -S -h /var/lib/sinopia sinopia

# Run as unprivileged, even under docker
USER sinopia
ENV HOME=/var/lib/sinopia
WORKDIR /var/lib/sinopia
COPY sinopia.sh /var/lib/sinopia/run.sh
EXPOSE 4873
ENTRYPOINT ["/var/lib/sinopia/run.sh"]
