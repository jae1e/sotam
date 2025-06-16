#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LOCAL_ROOT_DIR=$SCRIPT_DIR/../..
SSH_KEY=$SCRIPT_DIR/ec2_ed25519.pem
REMOTE_HOST=ubuntu@$SOTAM_BACKEND_IP
REMOTE_DIR="code"

# Check if remote directory exists and reset if needed
if ssh -i "$SSH_KEY" "$REMOTE_HOST" "[ -d '$REMOTE_DIR' ]"; then
    echo "Remote directory exists. Resetting it..."
    ssh -i "$SSH_KEY" "$REMOTE_HOST" "sudo rm -rf '$REMOTE_DIR'"
else
    echo "Remote directory does not exist. No need to reset."
fi
ssh -i "$SSH_KEY" "$REMOTE_HOST" "mkdir -p '$REMOTE_DIR'"
ssh -i "$SSH_KEY" "$REMOTE_HOST" "mkdir -p '$REMOTE_DIR/scripts'"

# Copy local directory to remote
echo "Copying local directory to remote..."
scp -i "$SSH_KEY" "$LOCAL_ROOT_DIR/docker-compose.yaml" "$REMOTE_HOST:$REMOTE_DIR"
scp -i "$SSH_KEY" "$LOCAL_ROOT_DIR/go.mod" "$REMOTE_HOST:$REMOTE_DIR"
scp -i "$SSH_KEY" "$LOCAL_ROOT_DIR/go.sum" "$REMOTE_HOST:$REMOTE_DIR"
scp -r -i "$SSH_KEY" "$LOCAL_ROOT_DIR/dockerfiles" "$REMOTE_HOST:$REMOTE_DIR/dockerfiles"
scp -r -i "$SSH_KEY" "$LOCAL_ROOT_DIR/scripts/docker" "$REMOTE_HOST:$REMOTE_DIR/scripts/docker"
scp -r -i "$SSH_KEY" "$LOCAL_ROOT_DIR/src" "$REMOTE_HOST:$REMOTE_DIR/src"

# Docker compose
echo "Building containers..."
ssh -i "$SSH_KEY" "$REMOTE_HOST" "cd $REMOTE_DIR && docker compose build"
echo "Builing container done"
