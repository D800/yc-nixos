#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Building NixOS qcow2 image..."
cd "$PROJECT_DIR"

nix build .#image -o result

IMAGE_PATH=$(readlink -f result)
echo "Image built successfully: $IMAGE_PATH"
echo "Image size: $(du -h "$IMAGE_PATH"/*.qcow2 | cut -f1)"
