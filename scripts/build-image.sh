#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Remote Linux builder для кросс-компиляции с macOS
# Формат: ssh-ng://user@host system ssh-key max-jobs speed-factor features
BUILDER_HOST="${BUILDER_HOST:-dimam@10.0.1.133}"
BUILDER_KEY="${BUILDER_KEY:-/var/root/.ssh/nixos-x3-ui-ed25519}"

cd "$PROJECT_DIR"

ARCH="$(uname -m)"
OS="$(uname -s)"

if [[ "$OS" == "Darwin" ]] || [[ "$ARCH" != "x86_64" ]]; then
  echo "Building NixOS qcow2 image via remote builder..."
  echo "Builder: $BUILDER_HOST (key: $BUILDER_KEY)"

  # Проверяем что пользователь trusted (может задавать builders)
  if ! nix show-config 2>/dev/null | grep -q "trusted-users.*$(whoami)"; then
    echo ""
    echo "ERROR: $(whoami) не в trusted-users nix daemon."
    echo "Исправить:"
    echo "  echo 'extra-trusted-users = $(whoami)' | sudo tee -a /etc/nix/nix.conf"
    echo "  sudo launchctl kickstart -k system/org.nixos.nix-daemon"
    echo ""
    exit 1
  fi

  nix build .#image -o result \
    --builders "ssh-ng://$BUILDER_HOST x86_64-linux $BUILDER_KEY 4 1 kvm,big-parallel,nixos-test,benchmark" \
    --max-jobs 0
else
  echo "Building NixOS qcow2 image locally..."
  nix build .#image -o result
fi

IMAGE_PATH=$(readlink -f result)
echo "Image built successfully: $IMAGE_PATH"
ls -lh "$IMAGE_PATH"
