#!/bin/sh

# ephemeral-npm env vars supported:
# [x] npm_config_registry
# [ ] MAX_BODY_SIZE
# [ ] MAX_USERS
# [x] MAXAGE
# [ ] TIMEOUT
# [ ] NPM_SECRET
# [ ] NPM_USER
# [ ] NPM_PASSWORD

export npm_config_registry=${npm_config_registry:-https://registry.npmjs.org}
export MAXAGE=${MAXAGE:-5m}

# necessary because nginx requires a resolver when upstreams are dynamic
dnsmasq --listen-address=127.0.0.1 --user=root

# in case /tmp/npm hasn't been created as a tmpfs already
mkdir -p /tmp/npm/store
mkdir -p /tmp/npm/temp
mkdir -p /tmp/npm/cache
# nginx runs as uid nobody and it needs write access
chown -R nobody /tmp/npm

exec /usr/local/openresty/bin/openresty -c /nginx.conf $*
