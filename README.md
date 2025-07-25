# Docker PostgreSQL Backup

[![Build Status](https://github.com/pilotso11/postgresql-backup/workflows/Test/badge.svg)](https://github.com/pilotso11/postgresql-backup/actions?query=workflow%3ATest)

Docker image that periodically dumps a Postgres database, and optionally uploads it to an Amazon S3 bucket.

Available on Docker Hub: [pilotso11/postgresql-backup](https://hub.docker.com/r/pilotso11/postgresql-backup)

## Example

```
docker run -it --rm --name=pgbackup \
    -e CRON_SCHEDULE="* * * * *" \
    -e DB_HOST=the.db.host \
    -e DB_USER=username \
    -e DB_PASS=password \
    -e DB_PASS_FILE=/run/secrets/db_password \
    -e DB_NAME=database_name \
    -e DB_NAMES="db1,db2,db3" \
    -e S3_PATH='s3://my-bucket/backups/' \
    -e AWS_ACCESS_KEY_ID='[aws key id]' \
    -e AWS_SECRET_ACCESS_KEY='[aws secret key]' \
    pilotso11/postgresql-backup:latest-pg15
```

## Required environment variables

* `CRON_SCHEDULE`: The time schedule part of a crontab file (e.g: `15 3 * * *` for every night 03:15)
* `DB_HOST`: Postgres hostname
* `DB_PASS`: Postgres password
* `DB_PASS_FILE`: Path to a file containing the Postgres password. If set, overrides `DB_PASS`.
* `DB_USER`: Postgres username
* `DB_NAME`: Name of database
* `DB_NAMES`: Comma-separated list of database names to back up. If set, overrides `DB_NAME` and backs up each listed database.

## Optional environment variables

* `S3_PATH`: Amazon S3 path in the format: s3://bucket-name/some/path
* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`
* `AWS_DEFAULT_REGION`
* `S3_STORAGE_CLASS`: Specify [storage class](https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-class-intro.html) for the uploaded object, defaults to `STANDARD_IA`.
* `S3_EXTRA_OPTIONS`: Specify additional options for S3, e.g. `--endpoint=` for using custom S3 provider.
* `DB_USE_ENV`: Inject [postgres environment variables](https://www.postgresql.org/docs/13/libpq-envars.html) from the environment. Ignores `DB_HOST`, `DB_PASS`, `DB_USER` and `DB_NAME`. Can be used to specify advanced connections, e.g. using mTLS connection.
    Example of `--env-file=.env` for container:
    ```
        DB_USE_ENV=True
        PGSSLMODE=verify-full
        PGSSLROOTCERT=/path/ca.crt
        PGSSLCERT=<path>/user.crt
        PGSSLKEY=<path>/user.key
        PGHOSTADDR=1.2.3.4
        PGHOST=db.domain.com
        PGUSER=myuser
        PGDATABASE=mydb
    ```
* `MAIL_TO`: If `MAIL_TO` and `MAIL_FROM` is specified, an e-mail will be sent, using Amazon SES, every time a backup is taken
* `MAIL_FROM`
* `WEBHOOK`: If specified, an HTTP request will be sent to this URL
* `WEBHOOK_METHOD`: By default the webhook's HTTP method is GET, but can be changed using this variable
* `WEBHOOK_CURL_OPTIONS`: Add additional headers or other option to curl command calling the webhook. E.g. `-H 'Content-type: application/json'`
* `WEBHOOK_DATA`: Add a body to the webhook being called, unless changed it implies that `POST` method is used. E.g. `{"text":"Backup completed at %(date)s %(time)s!"}`
* `KEEP_BACKUP_DAYS`: The number of days to keep backups for when pruning old backups. Defaults to `7`.
* `FILENAME`: String that is passed into `strftime()` and used as the backup dump's filename. Defaults to `$DB_NAME_%Y-%m-%d`.
* `PG_DUMP_EXTRA_OPTIONS`: Specify additional options for `pg_dump`, e.g. `--exclude-table-data=table_name` to exclude table data from the dump.

### Interpolation

Text in `WEBHOOK_DATA` is interpolated with variabels `%(my_var)s`
 - `date`: Date in yyyy-mm-dd format
 - `time`: Date in hh:mm:ss format
 - `duration`: Number of seconds take to backup
 - `filename`: Name of the file uploaded to S3
 - `size`: Size of the backup file with suitable suffix, like MB, GB, ...

#### Example on how to post a Slack message when a backup is complete

1. Configure a webhook as described in the Slack [documentation](https://api.slack.com/messaging/webhooks).
2. Set `WEBHOOK` and `WEBHOOK_` accodringly:
   ```
   WEBHOOK=https://hooks.slack.com/services/.../.../...
   WEBHOOK_METHOD=POST
   WEBHOOK_CURL_OPTIONS=-H 'Content-type: application/json'
   WEBHOOK_DATA={"text":":white_check_mark: Backup completed at %(date)s %(time)s\nDuration: %(duration)s seconds\nUpload: %(filename)s: %(size)s"}
    ```

## Volumes

* `/data/backups` - The database is dumped into this directory

## Restoring a backup

This image can also be run as a one off task to restore one of the backups.
To do this, we run the container with the command: `python -u /backup/restore.py [backup-filename]`
(`backup-filename` should only be the name of the file, the directory is set through the `S3_PATH` env variable, if it needs to be downloaded).

The following environment variables are required:

* `DB_HOST`: Postgres hostname
* `DB_PASS` or `DB_PASS_FILE`: Postgres password
* `DB_USER`: Postgres username
* `DB_NAME` or `DB_NAMES`: Name of database to import into

The following environment variables are required if the file to restore is not already in the backup volume:

* `S3_PATH`: Amazon S3 directory path in the format: s3://bucket-name/some/path
* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`
* `AWS_DEFAULT_REGION`

### Other optional environment variables

* `S3_EXTRA_OPTIONS`: Specify additional options for S3, e.g. `--endpoint=` for using custom S3 provider.
* `DB_USE_ENV`: See [Optional environment variables](#optional-environment-variables) above.

## Taking a one off backup

To run a one off backup job, e.g. to test that it works when setting it up for the first time, simply start
the container with the docker run command set to `python -u /backup/backup.py` (as well as all the required environment
variables set).

## Docker tags

This image uses the alpine version(s) of the [official postgres](https://hub.docker.com/_/postgres) image as base
image.

The following docker tags are available for this image, and they are based on the corresponding official postgres
alpine image:

* `latest-pg17`
* `latest-pg16`
* `latest-pg15`
* `latest-pg14`
* `latest-pg13`
* `latest-pg12`
* `latest-pg11`
* `latest-pg10`

Previous versions are available as well, but latest is recommended.
