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
# a list of other known repositories we can talk to
uplinks:
  upstream:
    url: $(npm config get registry)
packages:
  '@*/*':
    # scoped packages
    access: \$all
    publish: \$authenticated
  '*':
    access: \$all
    publish: \$authenticated
    proxy: upstream
logs:
  - {type: stdout, format: pretty, level: http}
EOYML

exec ./node_modules/.bin/sinopia --config ./config.yml
