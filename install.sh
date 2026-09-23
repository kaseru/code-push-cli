#!/usr/bin/env sh
set -eu

REPOSITORY="kaseru/code-push-cli"
REF="${CODE_PUSH_CLI_REF:-master}"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/code-push-cli"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
ARCHIVE_URL="https://github.com/${REPOSITORY}/archive/${REF}.tar.gz"

command -v node >/dev/null 2>&1 || {
    echo "Error: Node.js is required." >&2
    exit 1
}
command -v npm >/dev/null 2>&1 || {
    echo "Error: npm is required." >&2
    exit 1
}
command -v curl >/dev/null 2>&1 || {
    echo "Error: curl is required." >&2
    exit 1
}
command -v tar >/dev/null 2>&1 || {
    echo "Error: tar is required." >&2
    exit 1
}

TEMP_DIR="$(mktemp -d)"
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

curl --fail --location --silent --show-error "$ARCHIVE_URL" |
    tar -xz --strip-components=1 -C "$TEMP_DIR"

[ -f "$TEMP_DIR/src/cli.ts" ] || {
    echo "Error: downloaded source has no CLI entry point." >&2
    exit 1
}

npm install --include=dev --ignore-scripts --prefix "$TEMP_DIR"
npm run build --prefix "$TEMP_DIR"
npm prune --omit=dev --ignore-scripts --prefix "$TEMP_DIR"

rm -rf "$INSTALL_DIR"
mkdir -p "$(dirname "$INSTALL_DIR")" "$BIN_DIR"
mv "$TEMP_DIR" "$INSTALL_DIR"
trap - EXIT HUP INT TERM

cat > "$BIN_DIR/code-push" <<EOF
#!/usr/bin/env sh
exec node "$INSTALL_DIR/bin/cli.js" "\$@"
EOF
chmod 755 "$BIN_DIR/code-push"

echo "Installed code-push to $BIN_DIR/code-push"
