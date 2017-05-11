FROM openresty/openresty:alpine
MAINTAINER Ryan Graham <rmg@ca.ibm.com>

RUN apk --no-cache add dnsmasq

ADD entrypoint.sh nginx.conf ephemeral-npm.lua ephemeral-utils.lua /

# Not port 80 because ephemeral-npm standardized on couchdb's port already
EXPOSE 4873

ENTRYPOINT ["/entrypoint.sh"]
