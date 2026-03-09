#!/usr/bin/env bash
# Download and install the latest Multirole build from GitHub Releases.

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
RELEASE_URL="https://github.com/Secuter/MultiroleServerBuild/releases/latest/download/multirole-linux-x64.tar.gz"
INSTALL_DIR="/home/ubuntu/Multirole"
SERVICE_NAME="multirole"   # systemd service name — leave empty if not using systemd
# ─────────────────────────────────────────────────────────────────────────────

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "==> Checking installed runtime libraries..."
dpkg -l | grep -E 'libfmt|libgit2|libsqlite3|libssl|libboost' || true

echo ""
echo "==> Installing/updating runtime dependencies..."
sudo apt update -qq
sudo apt install --yes --no-install-recommends \
    libfmt8 \
    libgit2-1.1 \
    libsqlite3-0 \
    libssl3

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

echo "==> Installing Boost runtime libraries..."
if ls "$TMPDIR"/package/libboost_*.so.* 1>/dev/null 2>&1; then
    sudo cp -v "$TMPDIR"/package/libboost_*.so.* /usr/local/lib/
else
    echo "    WARNING: No Boost libraries found in artifact — skipping (must be installed manually)"
fi
# Ensure /usr/local/lib is in the dynamic linker search path
if [[ ! -f /etc/ld.so.conf.d/local.conf ]]; then
    echo "/usr/local/lib" | sudo tee /etc/ld.so.conf.d/local.conf
fi
sudo ldconfig

# Deploy config (always overwrite — config is version-controlled in the CI repo)
echo "==> Deploying config.json..."
cp -v "$TMPDIR/package/config.json" "$INSTALL_DIR/"

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
