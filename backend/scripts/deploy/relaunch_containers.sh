#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SSH_KEY=$SCRIPT_DIR/ec2_ed25519.pem
REMOTE_HOST=ubuntu@$SOTAM_BACKEND_IP
REMOTE_DIR="code"

# Restart docker-compose
echo "Running docker-compose..."
ssh -i "$SSH_KEY" "$REMOTE_HOST" "cd $REMOTE_DIR && docker compose down"
ssh -i "$SSH_KEY" "$REMOTE_HOST" "cd $REMOTE_DIR && docker compose up -d"

echo "Containers are relaunched"
