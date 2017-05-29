#!/bin/sh

function preSeed() {
  mkdir /tmp/seed
  tgz=$1
  tar -xzf $1 -C /tmp/seed
  shasum=$(shasum $tgz | cut -d' ' -f1)
  seedJson=/tmp/seed/package/package.json
  upstreamJson=/tmp/seed/upstream.json
  pkgName=$(cat $seedJson | jq -r .name)
  pkgVersion=$(cat $seedJson | jq -r .version)
  mkdir -p /tmp/npm/store/$pkgName

  cat <<-EOF
Preseeding with:
  name: "$pkgName"
  version: "$pkgVersion"
  shasum: "$shasum"
  tag: "latest"
EOF

  cat > /tmp/seed/seed.jq <<-EOJQ
  .versions["$pkgVersion"] |= \$seedJson[0]
  | .versions["$pkgVersion"].dist.shasum = \$shasum
  | .versions["$pkgVersion"].dist.tarball = "$npm_config_registry/$pkgName/-/$pkgName-$pkgVersion.tgz"
  | .["dist-tags"].latest = "$pkgVersion"
EOJQ

  curl -sL $npm_config_registry/$pkgName > $upstreamJson
  jq --from-file /tmp/seed/seed.jq \
    --slurpfile seedJson $seedJson \
    --arg shasum $shasum \
    --arg pkgName $pkgName \
    --arg pkgVersion $pkgVersion \
    $upstreamJson \
  > /tmp/npm/store/$pkgName/package.json
  cp $tgz /tmp/npm/store/$pkgName/$pkgName-$pkgVersion.tgz
}

function maybePreseed() {
  echo "checking if given a tarball..."
  cat - > /tmp/maybe.tgz
  echo "done reading input."
  if tar -tzf /tmp/maybe.tgz > /dev/null; then
    preSeed /tmp/maybe.tgz
  else
    echo 'no pre-seed package.'
  fi
}
