FROM node:4.0-slim
MAINTAINER StrongLoop <enginerring@strongloop.com>

# Run as unprivileged, even under docker
RUN adduser \
    --group \
    --system \
    --home /var/lib/sinopia \
    --disabled-password \
    --disabled-login \
    sinopia

USER sinopia

WORKDIR /var/lib/sinopia
ADD sinopia.sh /var/lib/sinopia/run.sh

RUN npm install --loglevel=warn --no-spin sinopia && \
    npm --no-spin --loglevel=warn cache clean && \
    rm -rf ~/.node-gyp

EXPOSE 4873

ENTRYPOINT ["/var/lib/sinopia/run.sh"]
