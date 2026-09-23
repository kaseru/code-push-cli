#!/usr/bin/env sh
set -eu

INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/code-push-cli"
BIN_PATH="${XDG_BIN_HOME:-$HOME/.local/bin}/code-push"

rm -f "$BIN_PATH"
rm -rf "$INSTALL_DIR"

echo "Uninstalled code-push"
