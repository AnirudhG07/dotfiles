#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="$HOME/.cargo/bin"
TMP_DIR="$(mktemp -d)"

echo "Using temp dir: $TMP_DIR"

# Ensure install directory exists
mkdir -p "$INSTALL_DIR"

# Get latest release JSON
API_URL="https://api.github.com/repos/sxyazi/yazi/releases/latest"

echo "Fetching latest release info..."
DOWNLOAD_URL=$(curl -s "$API_URL" \
  | grep "browser_download_url" \
  | grep "yazi-aarch64-apple-darwin.zip" \
  | cut -d '"' -f 4)

if [[ -z "$DOWNLOAD_URL" ]]; then
  echo "Failed to find download URL"
  exit 1
fi

echo "Downloading: $DOWNLOAD_URL"
curl -L "$DOWNLOAD_URL" -o "$TMP_DIR/yazi.zip"

echo "Extracting..."
unzip -q "$TMP_DIR/yazi.zip" -d "$TMP_DIR"

# Find extracted directory
EXTRACTED_DIR=$(find "$TMP_DIR" -type d -name "yazi-*" | head -n 1)

if [[ ! -d "$EXTRACTED_DIR" ]]; then
  echo "Extraction failed"
  exit 1
fi

echo "Installing binaries to $INSTALL_DIR"

install -m 755 "$EXTRACTED_DIR/yazi" "$INSTALL_DIR/yazi"
install -m 755 "$EXTRACTED_DIR/ya" "$INSTALL_DIR/ya"

echo "Cleaning up..."
rm -rf "$TMP_DIR"

echo "Done!"
echo "yazi installed at: $INSTALL_DIR/yazi"
echo "ya installed at:   $INSTALL_DIR/ya"
