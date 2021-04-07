FROM openresty/openresty:alpine
MAINTAINER Ryan Graham <rmg@ca.ibm.com>

RUN apk --no-cache add dnsmasq jq perl curl \
 && opm get pintsized/lua-resty-http

ADD entrypoint.sh nginx.conf ephemeral-npm.lua ephemeral-utils.lua preseed.sh /

# Make sure the base config file is valid
RUN mkdir -p /tmp/npm/cache /tmp/npm/store /tmp/npm/temp \
 && /usr/local/openresty/bin/openresty -t -c /nginx.conf \
 && rm -rf /tmp/npm

# Not port 80 because ephemeral-npm standardized on couchdb's port already
EXPOSE 4873

ENTRYPOINT ["/entrypoint.sh"]
