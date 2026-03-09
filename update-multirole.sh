#!/usr/bin/env bash
# update-server.sh — Download and install the latest Multirole build from GitHub Releases.
#
# Usage:
#   ./update-server.sh [INSTALL_DIR]
#
# INSTALL_DIR defaults to the directory where the script lives.
# Adjust SERVICE_NAME if you run multirole as a systemd service.

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
RELEASE_URL="https://github.com/Secuter/MultiroleServerBuild/releases/download/continuous/multirole-linux-x64.tar.gz"
INSTALL_DIR="${1:-$(dirname "$(realpath "$0")")}"
SERVICE_NAME=""   # e.g. "multirole" — leave empty if not using systemd
# ─────────────────────────────────────────────────────────────────────────────

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "==> Checking installed runtime libraries..."
dpkg -l | grep -E 'libfmt|libgit2|libsqlite3|libssl|libboost' || true

echo ""
echo "==> Installing/updating runtime dependencies..."
sudo apt update -qq
sudo apt install --yes --no-install-recommends software-properties-common
sudo add-apt-repository --yes ppa:mhier/libboost-latest
sudo apt update -qq
sudo apt install --yes --no-install-recommends \
    libfmt8 \
    libgit2-1.1 \
    libsqlite3-0 \
    libssl3 \
    libboost1.83

echo ""
echo "==> Downloading artifact from: $RELEASE_URL"
curl -fsSL -o "$TMPDIR/multirole-linux-x64.tar.gz" "$RELEASE_URL"

echo "==> Extracting to $TMPDIR/package..."
mkdir -p "$TMPDIR/package"
tar -xzf "$TMPDIR/multirole-linux-x64.tar.gz" -C "$TMPDIR/package"

# Stop service if configured
if [[ -n "$SERVICE_NAME" ]]; then
    echo "==> Stopping $SERVICE_NAME..."
    sudo systemctl stop "$SERVICE_NAME" || true
fi

echo "==> Installing binaries to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp -v "$TMPDIR/package/multirole"    "$INSTALL_DIR/"
cp -v "$TMPDIR/package/hornet"       "$INSTALL_DIR/"
cp -v "$TMPDIR/package/area-zero.sh" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/multirole" "$INSTALL_DIR/hornet" "$INSTALL_DIR/area-zero.sh"

# Copy config only if not already present (avoid overwriting local config)
if [[ ! -f "$INSTALL_DIR/config.json" ]]; then
    echo "==> Installing default config.json (not found in $INSTALL_DIR)..."
    cp -v "$TMPDIR/package/config.json" "$INSTALL_DIR/"
else
    echo "==> Skipping config.json (already exists — not overwritten)"
    echo "    New default is at: $TMPDIR/package/config.json (check for new options)"
fi

# Restart service if configured
if [[ -n "$SERVICE_NAME" ]]; then
    echo "==> Starting $SERVICE_NAME..."
    sudo systemctl start "$SERVICE_NAME"
    systemctl status "$SERVICE_NAME" --no-pager
fi

echo ""
echo "==> Done. Installed versions:"
"$INSTALL_DIR/multirole" --version 2>/dev/null || true
ls -lh "$INSTALL_DIR/multirole" "$INSTALL_DIR/hornet"
