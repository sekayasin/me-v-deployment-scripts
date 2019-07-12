#!/bin/bash
#make a backup of the database
#var to hold date timestamp
dump_date= `date + "%Y"`-`date +"%m"`-`date +"%d"`
pg_dump -F p -f /home/vof/backups/gcp/vof-production-db-backup-$dump_date.sql
#post the backup to GCP
#post to bucket
gsutils cp /home/vof/backups/gcp/vof-production-db-backup-$dump_date.sql  gs://vof-tracker-app/database-backups/vof-production-db-backup-$dump_date.sql
#prune old backups
find /home/vof/backups/gcp/ -maxdepth 1 -mtime +14 -name "*sql" exec rm -rf '{}' ';'