#!/bin/sh

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
    url: ${npm_config_registry:-https://registry.npmjs.org/}
    maxage: ${MAXAGE:-5m}
    timeout: ${TIMEOUT:-45s}
packages:
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
  echo "$NPM_USER:{PLAIN}$NPM_PASSWORD" > ./htpasswd
fi

exec sinopia --config ./config.yml
