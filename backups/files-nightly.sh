#!/bin/bash

set -euo pipefail

cd /

echo "[INFO] Setting up SSH configuration"

mkdir -p ~/.ssh
chmod 0700 ~/.ssh

echo -n "$SSH_REMOTE $SSH_FINGERPRINT" >/etc/ssh/ssh_known_hosts

echo -n "$SSH_PRIVATE_KEY" >~/.ssh/id_rsa
chmod 0600 ~/.ssh/id_rsa
unset SSH_PRIVATE_KEY

ssh_target="$SSH_USERNAME@$SSH_REMOTE"
backup_path="files/$CLUSTER_NAME/$BACKUPS_SITE/"

# Is the file system empty? If so, don't do anything (we don't want to accidentally purge our rsync remote)
if test "$(echo /mnt/filesystem/*)" == "/mnt/filesystem/*"; then
  echo "[INFO] /mnt/filesystem is currently empty; skipping backups"
  exit 0
fi

echo "[INFO] Preparing $backup_path on $ssh_target"
ssh "$ssh_target" mkdir -p "$backup_path"

echo "[INFO] Syncing /mnt/filesystem for $CLUSTER_NAME/$BACKUPS_SITE to $ssh_target"
rsync -arz --delete /mnt/filesystem/ "$ssh_target:$backup_path"

echo "[INFO] Sync complete. Uploading tarballs for $BACKUPS_SITE to S3"

readonly nightly_tar=/tmp/nightly.tar.gz
timestamp="$(date +%Y-%m-%d)"

ok=ok

for dir in /mnt/filesystem/*; do
  # Clean up the tarball in case aws s3 mv didn't remove it for some reason
  rm -f "$nightly_tar"

  env="$(basename "$dir")"
  if ! test -d "$dir"; then
    echo "$dir is not a directory; skipping backup"
    continue
  fi

  echo "[INFO] Creating tarball of $env from EFS"
  if ! tar czf "$nightly_tar" -C "$dir" .; then
    ok=
    continue
  fi

  echo "[INFO] Uploading tarball of $env to S3"
  if ! aws s3 mv --only-show-errors "$nightly_tar" "s3://$BACKUPS_BUCKET/files/$BACKUPS_SITE/$timestamp/$env.tar.gz"; then
    ok=
    continue
  fi

done

if test -z "$ok"; then
  echo "[ERROR] One or more backups to S3 failed."
  exit 1
fi
