#!/bin/bash

SSH_KEY="~/.ssh/id_rsa_fenix_screen"
REMOTE_USER="root"
REMOTE_HOST="146.190.200.50"
REMOTE_DIR="/root/nobelproducts"

ITEM_LIST=(
  "./environments"
  "./images"
  "./deploy.sh"
  "./docker-compose.yml"
  "./init-certs.sh"
  "./renew-certs.sh"
)

for ITEM in "${ITEM_LIST[@]}"; do
   if [[ -f "$ITEM" ]]; then
    echo "Syncing file $ITEM to $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"
    rsync -avz -e "ssh -i $SSH_KEY" "$ITEM" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"

  elif [[ -d "$ITEM" ]]; then
    echo "Syncing directory $ITEM to $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"
    rsync -avz -e "ssh -i $SSH_KEY" "$ITEM" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"

  else
    echo "File or directory $ITEM not found locally, skipping."
  fi
done

echo "Rsync operation completed."