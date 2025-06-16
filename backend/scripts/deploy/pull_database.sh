#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DATA_DIR=$SCRIPT_DIR/../../data
DATABASE_NAME="hospital_database"

SSH_KEY=$SCRIPT_DIR/ec2_ed25519.pem
REMOTE_HOST=ubuntu@$SOTAM_BACKEND_IP

CONTAINER_NAME="mongo"

# Dump current remote database to file
TODAY=$(date '+%Y-%m-%d')
CONTAINER_BACKUP_DIR=/mongodump/backup/$TODAY
ssh -i "$SSH_KEY" "$REMOTE_HOST" \
    "docker exec $CONTAINER_NAME mongodump --db $DATABASE_NAME \
    --out $CONTAINER_BACKUP_DIR"
echo "Dumped current database to $CONTAINER_BACKUP_DIR"

# Copy remote database to local
echo "Copying remote database to local..."
PULL_DIR=$DATA_DIR/mongodump/pull
REMOTE_BACKUP_DIR=mongodump/backup/$TODAY
mkdir -p "$PULL_DIR"
scp -r -i "$SSH_KEY" "$REMOTE_HOST:$REMOTE_BACKUP_DIR" "$PULL_DIR"

# Backup current local database to file
LOCAL_BACKUP_DIR=$DATA_DIR/mongodump/backup/$TODAY
mongodump --db "$DATABASE_NAME" --out "$LOCAL_BACKUP_DIR"
echo "Backed up current database to $LOCAL_BACKUP_DIR"

# Load database to local
echo "Loading database..."
LOAD_DIR=$PULL_DIR/$TODAY/$DATABASE_NAME
mongorestore --drop --db "$DATABASE_NAME" --dir "$LOAD_DIR"
echo "$LOAD_DIR is loaded"
