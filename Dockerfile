FROM node:4-alpine
MAINTAINER Ryan Graham <rmg@ca.ibm.com>

COPY verdaccio /opt/verdaccio
RUN cd /opt/verdaccio \
 && npm link --production --no-spin \
 && rm -rf ~/.npm* ~/.gnupg /tmp/npm* /usr/local/lib/node_modules/npm ~/.node* /var/cache/apk/* /usr/local/include/node \
 && adduser -S -h /var/lib/sinopia sinopia

# Run as unprivileged, even under docker
USER sinopia
ENV HOME=/var/lib/sinopia
WORKDIR /var/lib/sinopia
COPY sinopia.sh /var/lib/sinopia/run.sh
EXPOSE 4873
ENTRYPOINT ["/var/lib/sinopia/run.sh"]
