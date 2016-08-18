FROM node:4-slim
MAINTAINER Ryan Graham <rmg@ca.ibm.com>

# Run as unprivileged, even under docker
RUN adduser \
    --group \
    --system \
    --home /var/lib/sinopia \
    --disabled-password \
    --disabled-login \
    sinopia

COPY verdaccio /opt/verdaccio
RUN cd /opt/verdaccio \
 && npm link --production --loglevel=warn --no-spin \
 && rm -rf ~/.npm ~/.node-gyp

USER sinopia
ENV HOME=/var/lib/sinopia

WORKDIR /var/lib/sinopia

COPY sinopia.sh /var/lib/sinopia/run.sh

EXPOSE 4873

ENTRYPOINT ["/var/lib/sinopia/run.sh"]
