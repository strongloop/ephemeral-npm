#!/bin/bash

#cat <<EOYML
cat > ./config.yml <<EOYML
storage: ./storage
listen:
  - 0.0.0.0:4873
auth:
  htpasswd:
    file: ./htpasswd
    max_users: ${MAX_USERS:-1}
uplinks:
  upstream:
    url: $(npm config get registry)
packages:
  '*':
    access: \$all
    publish: \$authenticated
    proxy: upstream
logs:
  - {type: stdout, format: pretty, level: info}
EOYML

echo "${NPM_USER:-admin}:{PLAIN}${NPM_PASSWORD:-admin}" > ./htpasswd

exec ./node_modules/.bin/sinopia --config ./config.yml
