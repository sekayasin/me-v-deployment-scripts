#!/bin/bash
#var to hold date timestamp
dump_date= `date + "%Y"`-`date +"%m"`-`date +"%d"`
#pull the production database from GCP
gsutils cp gs://vof-tracker-app/database-backups/vof-production-db-backup-$dump_date.sql /home/vof/vof-production-db-backup-$dump_date.sql
#clear the database before importing
sudo -u postgres bash -c "export PGPASSWORD=$(get_var "databasePassword"); dropdb '$(get_var "databaseName")' "
#force import to staging
sudo -u postgres bash -c "export PGPASSWORD=$(get_var "databasePassword"); psql -h  $(get_var "databaseHost") -p 5432 -U $(get_var "databaseUser") -d $(get_var "databaseName") < /home/vof/vof-production-db-backup-`date + "%Y"`-`date +"%m"`-`date +"%d"`.sql"
  