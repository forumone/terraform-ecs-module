FROM debian:stable-slim

RUN set -eux \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    openssh-client \
    rsync \
    mariadb-client \
    awscli \ 
  && rm -rf /var/apt/lists/*

COPY ssh_config /etc/ssh/ssh_config.d/backups

COPY files-nightly.sh /usr/local/bin/files-nightly.sh
COPY database-nightly-mysql.sh /usr/local/bin/database-nightly-mysql.sh
RUN chmod +x \
  /usr/local/bin/files-nightly.sh \
  /usr/local/bin/database-nightly-mysql.sh
