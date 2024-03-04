#!/bin/bash

set -euo pipefail

cd /

echo "[INFO] Setting up SSH configuration"
mkdir -p ~/.ssh
chmod 0700 ~/.ssh

echo -n "$SSH_REMOTE $SSH_FINGERPRINT" >/etc/ssh/ssh_known_hosts

echo "$SSH_PRIVATE_KEY" >~/.ssh/id_rsa
chmod 0600 ~/.ssh/id_rsa
unset SSH_PRIVATE_KEY

# Save connection arguments
mysql_args=(
  --host="$DATABASE_HOST"
  --user="$DATABASE_USERNAME"
  --password="$DATABASE_PASSWORD"
)

echo "[INFO] Listing databases in MySQL"

# Get all the databases into an array variable
readarray -t databases < <(
  mysql \
    "${mysql_args[@]}" \
    --batch \
    --skip-column-names \
    --execute "SHOW DATABASES"
)

echo "[INFO] Databases found: ${#databases[@]}"

# Canary to determine
ok=ok

timestamp="$(date +%Y-%m-%d)"

readonly local_path=/tmp/nightly.sql.gz

for database in "${databases[@]}"; do
  if [[ "$database" =~ ^(information_schema|performance_schema|mysql|sys|tmp)$ ]]; then
    continue
  fi

  # Remove the dump file in case aws s3 mv didn't from the prior loop iteration
  rm -f "$local_path"

  # $dump_name converts a string like "proj-dev-web" to "proj/YYYY-MM-DD-dev-web.sql.gz"
  dump_name="${database/-//$timestamp-}.sql.gz"

  remote_path="$CLUSTER_NAME/databases/$dump_name"

  # Needed to run mkdir -p on the remote end
  remote_dir="$(dirname "$remote_path")"

  echo "[INFO] Performing MySQL dump of $database"
  if ! mysqldump "${mysql_args[@]}" --single-transaction --opt "$database" | gzip >"$local_path"; then
    echo "[ERROR] Failed to dump $database"
    ok=
    continue
  fi

  echo "[INFO] Uploading dump to S3"
  if ! aws s3 cp --only-show-errors "$local_path" "s3://$BACKUPS_BUCKET/database/$dump_name"; then
    ok=

    # Don't use 'continue' here, we still need to push to offsite
  fi

  echo "[INFO] Preparing $remote_dir"
  if ! ssh "$SSH_USERNAME@$SSH_REMOTE" mkdir -p "$remote_dir"; then
    ok=
    continue
  fi

  echo "[INFO] Copying dump to $remote_path"
  if ! scp "$local_path" "$SSH_USERNAME@$SSH_REMOTE:$remote_path"; then
    ok=
    continue
  fi

  echo "Copied $database to S3 and $SSH_REMOTE"
done

if test -z "$ok"; then
  echo "[ERROR] One or more backup steps failed."
  exit 1
fi
