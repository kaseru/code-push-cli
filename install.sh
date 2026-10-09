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

PATH_MARKER_START="# >>> code-push-cli >>>"
PATH_MARKER_END="# <<< code-push-cli <<<"

add_to_path() {
    profile="$1"
    syntax="$2"
    [ -f "$profile" ] && grep -qF "$PATH_MARKER_START" "$profile" && return 0
    mkdir -p "$(dirname "$profile")"
    {
        echo ""
        echo "$PATH_MARKER_START"
        if [ "$syntax" = fish ]; then
            echo "fish_add_path -g \"$BIN_DIR\""
        else
            echo "case \":\$PATH:\" in *\":$BIN_DIR:\"*) ;; *) export PATH=\"$BIN_DIR:\$PATH\" ;; esac"
        fi
        echo "$PATH_MARKER_END"
    } >> "$profile"
    echo "Added $BIN_DIR to PATH in $profile"
}

case ":$PATH:" in
    *":$BIN_DIR:"*) exit 0 ;;
esac

if [ "${CODE_PUSH_CLI_NO_MODIFY_PATH:-}" = 1 ]; then
    echo "Add $BIN_DIR to your PATH to use code-push."
    exit 0
fi

case "$(basename "${SHELL:-sh}")" in
    zsh)
        add_to_path "${ZDOTDIR:-$HOME}/.zshrc" sh
        ;;
    bash)
        add_to_path "$HOME/.bashrc" sh
        if [ -f "$HOME/.bash_profile" ]; then
            add_to_path "$HOME/.bash_profile" sh
        else
            add_to_path "$HOME/.profile" sh
        fi
        ;;
    fish)
        add_to_path "${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/code-push-cli.fish" fish
        ;;
    *)
        add_to_path "$HOME/.profile" sh
        ;;
esac

echo "Open a new terminal, or run: export PATH=\"$BIN_DIR:\$PATH\""
