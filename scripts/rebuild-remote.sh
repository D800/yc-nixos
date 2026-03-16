#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

TARGET_HOST="${1:-}"

if [ -z "$TARGET_HOST" ]; then
  # Попробуем получить IP из terraform output
  TF_DIR="$PROJECT_DIR/terraform"
  if [ -f "$TF_DIR/terraform.tfstate" ]; then
    TARGET_HOST="admin@$(cd "$TF_DIR" && tofu output -raw external_ip 2>/dev/null)" || true
  fi

  if [ -z "$TARGET_HOST" ] || [ "$TARGET_HOST" = "admin@" ]; then
    echo "Usage: $0 [admin@<IP>]"
    echo "  Or set terraform state in terraform/"
    exit 1
  fi
fi

echo "Rebuilding NixOS on $TARGET_HOST..."
cd "$PROJECT_DIR"

nixos-rebuild switch \
  --flake ".#yc-nixos" \
  --target-host "$TARGET_HOST" \
  --use-remote-sudo

echo "Rebuild completed successfully!"
