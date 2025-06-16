#!/bin/bash
DATABASE_NAME="hospital_database"
BACKUP_LATEST_DIR="/mongodump/backup_latest"

rm -rf $BACKUP_LATEST_DIR
mongodump --db $DATABASE_NAME --out $BACKUP_LATEST_DIR

rm -f $BACKUP_ZIP_NAME
tar -C $BACKUP_LATEST_DIR -zcvf $BACKUP_LATEST_DIR.tar.gz $DATABASE_NAME
echo "Created backup $BACKUP_ZIP_NAME from $BACKUP_LATEST_DIR"
