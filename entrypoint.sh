#!/bin/sh

# ephemeral-npm env vars supported:
# [x] npm_config_registry
# [ ] MAX_BODY_SIZE
# [ ] MAX_USERS
# [ ] MAXAGE
# [ ] TIMEOUT
# [ ] NPM_SECRET
# [ ] NPM_USER
# [ ] NPM_PASSWORD

export npm_config_registry=${npm_config_registry:-https://registry.npmjs.org}

# necessary because nginx requires a resolver when upstreams are dynamic
dnsmasq --listen-address=127.0.0.1 --user=root

# in case it hasn't been created as a tmpfs already
mkdir -p /tmp/npm

exec /usr/local/openresty/bin/openresty -c /nginx.conf $*
