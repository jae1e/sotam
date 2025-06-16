#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DATA_DIR=$SCRIPT_DIR/../../data
DATABASE_NAME="hospital_database"

SSH_KEY=$SCRIPT_DIR/ec2_ed25519.pem
REMOTE_HOST=ubuntu@$SOTAM_BACKEND_IP

# Dump database to file
LOCAL_DIR="$DATA_DIR/$DATABASE_NAME"
rm -rf "$LOCAL_DIR"
mongodump --db "$DATABASE_NAME" --out "$DATA_DIR"
echo "Exported database to $LOCAL_DIR"

# Copy local database to remote
echo "Copying local database to remote..."
TODAY=$(date '+%Y-%m-%d')
PUSH_DIR=mongodump/push/$TODAY
ssh -i "$SSH_KEY" "$REMOTE_HOST" "mkdir -p $PUSH_DIR"
scp -r -i "$SSH_KEY" "$DATA_DIR/$DATABASE_NAME" "$REMOTE_HOST:$PUSH_DIR"

CONTAINER_NAME="mongo"

# Backup current remote database to file
CONTAINER_BACKUP_DIR=/mongodump/backup/$TODAY
ssh -i "$SSH_KEY" "$REMOTE_HOST" \
    "docker exec $CONTAINER_NAME mongodump --db $DATABASE_NAME \
    --out $CONTAINER_BACKUP_DIR"
echo "Backed up current database to $CONTAINER_BACKUP_DIR"

# Load database to remote
echo "Loading database..."
CONTAINER_LOAD_DIR=/mongodump/push/$TODAY/$DATABASE_NAME
ssh -i "$SSH_KEY" "$REMOTE_HOST" \
    "docker exec $CONTAINER_NAME mongorestore --drop --db $DATABASE_NAME \
    --nsExclude \"$DATABASE_NAME.surveys\" \
    --nsExclude \"$DATABASE_NAME.likes\" \
    --nsExclude \"$DATABASE_NAME.users\" \
    --nsExclude \"$DATABASE_NAME.announcements\" \
    --dir $CONTAINER_LOAD_DIR"
echo "$CONTAINER_LOAD_DIR is loaded"
