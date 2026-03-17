FROM alpine:3.20

RUN apk add --no-cache \
    postgresql16-client \
    rclone \
    bash \
    gzip \
    dcron \
    tzdata

COPY backup.sh basebackup.sh prune.sh /scripts/
RUN chmod +x /scripts/*.sh

COPY crontab /etc/crontabs/root

RUN mkdir -p /tmp/backups

CMD ["crond", "-f", "-l", "2"]
