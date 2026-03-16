#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TF_DIR="$PROJECT_DIR/terraform"

echo "Deploying with OpenTofu..."
cd "$TF_DIR"

tofu init
tofu plan
echo ""
read -r -p "Apply changes? [y/N] " response
if [[ "$response" =~ ^[yY]$ ]]; then
  tofu apply -auto-approve

  EXTERNAL_IP=$(tofu output -raw external_ip)
  echo ""
  echo "VM deployed successfully!"
  echo "External IP: $EXTERNAL_IP"
  echo ""
  echo "Waiting for SSH to become available..."
  for i in $(seq 1 30); do
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "admin@${EXTERNAL_IP}" true 2>/dev/null; then
      echo "SSH is ready!"
      echo ""
      echo "Connect: ssh admin@${EXTERNAL_IP}"
      exit 0
    fi
    echo "  Attempt $i/30..."
    sleep 10
  done
  echo "WARNING: SSH not available after 5 minutes. Check YC console."
else
  echo "Cancelled."
fi
