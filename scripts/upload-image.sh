#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

BUCKET_NAME="${YC_BUCKET:-yc-nixos-images}"
IMAGE_NAME="nixos-yc-$(date +%Y%m%d-%H%M%S)"
QCOW2_PATH="$PROJECT_DIR/result/nixos.qcow2"

if [ ! -f "$QCOW2_PATH" ]; then
  # Поиск qcow2 в result/
  QCOW2_PATH=$(find "$PROJECT_DIR/result" -name "*.qcow2" | head -1)
  if [ -z "$QCOW2_PATH" ]; then
    echo "ERROR: qcow2 image not found. Run build-image.sh first."
    exit 1
  fi
fi

echo "Uploading image to Object Storage: $QCOW2_PATH"
echo "Bucket: $BUCKET_NAME"
echo "Image name: $IMAGE_NAME"

# Загрузка в Object Storage
yc storage s3api put-object \
  --bucket "$BUCKET_NAME" \
  --key "${IMAGE_NAME}.qcow2" \
  --body "$QCOW2_PATH"

echo "Creating compute image from Object Storage..."
yc compute image create \
  --name "$IMAGE_NAME" \
  --description "NixOS k3s image" \
  --os-type linux \
  --source-uri "https://storage.yandexcloud.net/${BUCKET_NAME}/${IMAGE_NAME}.qcow2"

IMAGE_ID=$(yc compute image get --name "$IMAGE_NAME" --format json | jq -r '.id')
echo ""
echo "Image created successfully!"
echo "Image ID: $IMAGE_ID"
echo ""
echo "Use in terraform.tfvars:"
echo "  image_id = \"$IMAGE_ID\""
