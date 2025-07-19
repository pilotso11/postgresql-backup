FROM postgres:%VERSION%-alpine

# Install dependencies
RUN apk add --no-cache -uv curl aws-cli python3

VOLUME ["/data/backups"]

ENV BACKUP_DIR=/data/backups

ADD . /backup
RUN chmod +x /backup/*.sh

ENTRYPOINT ["/backup/entrypoint.sh"]

CMD ["crond", "-f", "-l", "2"]
