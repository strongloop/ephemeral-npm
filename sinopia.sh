#!/bin/bash

#cat <<EOYML
cat > ./config.yml <<EOYML
storage: ./storage
listen:
  - 0.0.0.0:4873
max_body_size: ${MAX_BODY_SIZE:-100mb}
auth:
  htpasswd:
    file: ./htpasswd
    max_users: ${MAX_USERS:-1}
uplinks:
  upstream:
    url: $(npm config get registry)
    maxage: ${MAXAGE:-5m}
    timeout: ${TIMEOUT:-45s}
packages:
  '@*/*':
    access: \$all
    publish: \$authenticated
    proxy: upstream
  '*':
    access: \$all
    publish: \$authenticated
    proxy: upstream
logs:
  - {type: stdout, format: pretty, level: info}
EOYML

if [ -n "$NPM_SECRET" ]; then
  echo "secret: $NPM_SECRET" >> config.yml
fi
if [ -n "$NPM_USER" -a -n "$NPM_PASSWORD" ]; then
  echo "$NPM_USER:{PLAIN}$NPM_PASSWORD" >> ./htpasswd
fi

# busybox: timeout [-t SECS] [-s SIG] PROG ARGS
#   => only accepts seconds
# coreutils: timeout DURATION COMMAND [ARG]...
#   => DURATION can have s, m, h, or d suffix for units

if [ -n "$MAXIMIMUM_LIFETIME" ]; then
  if grep -q alpine /etc/os-release; then
    exec timeout -t $MAXIMUM_LIFETIME /usr/local/bin/verdaccio --config ./config.yml
  else
    exec timeout --preserve-status --foreground $MAXIMUM_LIFETIME /usr/local/bin/verdaccio --config ./config.yml
  fi
else
  exec /usr/local/bin/verdaccio --config ./config.yml
fi
