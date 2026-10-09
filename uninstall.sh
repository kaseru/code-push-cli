#!/usr/bin/env sh
set -eu

INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/code-push-cli"
BIN_PATH="${XDG_BIN_HOME:-$HOME/.local/bin}/code-push"

rm -f "$BIN_PATH"
rm -rf "$INSTALL_DIR"

for profile in \
    "$HOME/.profile" \
    "$HOME/.bashrc" \
    "$HOME/.bash_profile" \
    "${ZDOTDIR:-$HOME}/.zshrc"; do
    [ -f "$profile" ] && grep -qF "# >>> code-push-cli >>>" "$profile" || continue
    temp_file="$(mktemp)"
    awk '
        $0 == "# >>> code-push-cli >>>" { skip = 1; next }
        $0 == "# <<< code-push-cli <<<" { skip = 0; next }
        !skip
    ' "$profile" > "$temp_file"
    cat "$temp_file" > "$profile"
    rm -f "$temp_file"
done
rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/code-push-cli.fish"

echo "Uninstalled code-push"
