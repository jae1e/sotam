#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SSH_KEY=$SCRIPT_DIR/ec2_ed25519.pem
REMOTE_HOST=ubuntu@$SOTAM_BACKEND_IP

echo "Clearing none images..."
ssh -i "$SSH_KEY" "$REMOTE_HOST" 'docker rmi $(docker images -f "dangling=true" -q)'
