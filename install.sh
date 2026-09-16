#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# equisdots · login — install the minimized static SDDM theme.
#
# One-time sudo: copies the theme, selects it and disables the on-screen
# keyboard. Nothing at runtime ever writes to the theme again (no palette
# sync, no silent sudo -> no pam_faillock risk).
#
# Usage:
#   ./install.sh              install/update the theme
#   ./install.sh --uninstall  remove the theme and its sddm config
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="/usr/share/sddm/themes/x"
CONF_DIR="/etc/sddm.conf.d"

usage() {
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
    -h|--help)
        usage
        ;;
    --uninstall)
        echo ":: removing the x theme and its sddm config"
        sudo rm -rf "$THEME_DIR"
        sudo rm -f "$CONF_DIR/10-x-theme.conf" "$CONF_DIR/z-disable-virtualkbd.conf"
        echo ":: done"
        ;;
    "")
        echo ":: installing the minimal SDDM theme (static black/white)"
        sudo mkdir -p "$THEME_DIR" "$CONF_DIR"
        sudo cp -r "$DIR/theme/x/." "$THEME_DIR/"
        # leftovers from the old palette-synced theme
        sudo rm -f "$THEME_DIR/Colors.qml" "$THEME_DIR/wallpaper.jpg" "$THEME_DIR/qmldir"
        printf '[Theme]\nCurrent=x\n' | sudo tee "$CONF_DIR/10-x-theme.conf" >/dev/null
        if [[ -f "$CONF_DIR/theme.conf.user" ]]; then
            sudo mv "$CONF_DIR/theme.conf.user" "$CONF_DIR/theme.conf.user.bak"
            echo ":: disabled conflicting theme.conf.user (kept as .bak)"
        fi
        sudo cp "$DIR/z-disable-virtualkbd.conf" "$CONF_DIR/z-disable-virtualkbd.conf"
        if command -v sddm >/dev/null 2>&1; then
            sudo systemctl enable sddm.service 2>/dev/null || true
        fi
        echo ":: theme 'x' installed and selected"
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
