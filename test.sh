#!/bin/bash

mkdir -p ./tmp
mkdir -p ./out
cp template/* tmp/
sed s/%VERSION%/17/g template/Dockerfile > tmp/Dockerfile
docker build -t postgressql-backup:test-17 tmp
docker run --rm -it \
  -e DB_HOST=192.168.2.5 \
  -e DB_PORT=5432 \
  -e DB_USER=pg \
  -e DB_PASS_FILE=/secrets/pg_secret.txt \
  -e DB_NAMES="postgres, gitea" \
  -e KEEP_BACKUP_DAYS=1 \
  -v ./.secrets:/secrets \
  -v ./out:/data/backups \
  --entrypoint "/bin/bash" \
  --entrypoint "/backup/run.sh" \
  postgressql-backup:test-17


