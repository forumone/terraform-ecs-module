#!/bin/bash

set -euo pipefail

readonly paths=(
  .
  sso
  cluster
  cluster/application
  cluster/traefik
  tf_mysql_aurora
  tf_postgresql_aurora
)

for path in "${paths[@]}"; do
  echo "Updating $path"
  bash scripts/check-docs.sh "$path" >&/dev/null || true
done
