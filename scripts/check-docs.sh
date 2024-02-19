#!/bin/bash

set -euo pipefail

readonly terraform_docs=quay.io/terraform-docs/terraform-docs:0.16.0

readonly directory="$1"

cd "$directory"

echo "--- Checking README.md status"
docker run --rm \
  --volume "$(pwd):/terraform-docs" \
  "$terraform_docs" \
  /terraform-docs

if ! git diff --quiet README.md; then
  echo "^^^ +++"
  echo "ERROR: README.md not up to date"
  exit 1
fi
