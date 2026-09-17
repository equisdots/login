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
DM_LINK="/etc/systemd/system/display-manager.service"

usage() {
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
}

# ┌───────────────────────────────────────────────────────────────────────────┐
# │ DISPLAY MANAGER SELECTION                                                 │
# └───────────────────────────────────────────────────────────────────────────┘
# The theme is only shown by SDDM. Other display managers (plasmalogin, gdm,
# lightdm, ly, greetd...) may own display-manager.service, in which case SDDM
# never starts and the theme is never seen. Keeps a backup of the current
# symlink and switches it to SDDM (undo with --uninstall).
select_display_manager() {
    if ! command -v sddm >/dev/null 2>&1; then
        echo ":: sddm is not installed; skipping display manager selection"
        return 0
    fi

    local current="" fragment=""
    [[ -L "$DM_LINK" ]] && current="$(basename "$(readlink "$DM_LINK")")"
    fragment="$(systemctl show -p FragmentPath --value sddm.service 2>/dev/null || true)"
    [[ -n "$fragment" ]] || fragment="/usr/lib/systemd/system/sddm.service"

    if [[ "$current" == "sddm.service" ]]; then
        sudo systemctl enable sddm.service >/dev/null 2>&1 || true
        echo ":: SDDM is already the active display manager"
        return 0
    fi

    if [[ -n "$current" ]]; then
        echo ":: active display manager: $current (not SDDM)"
        if [[ ! -e "$DM_LINK.equisdots-backup" ]]; then
            sudo cp -a "$DM_LINK" "$DM_LINK.equisdots-backup" 2>/dev/null || true
        fi
        # Drop the other DM's alias before claiming display-manager.service.
        sudo systemctl disable "$current" >/dev/null 2>&1 || true
    else
        echo ":: no display manager selected yet"
    fi

    sudo ln -sf "$fragment" "$DM_LINK"
    sudo systemctl enable sddm.service >/dev/null 2>&1 || true

    if [[ "$(basename "$(readlink "$DM_LINK" 2>/dev/null || true)")" == "sddm.service" ]]; then
        echo ":: display-manager.service -> sddm.service (previous kept at $DM_LINK.equisdots-backup)"
        echo ":: log out or reboot to see the login theme"
    else
        echo ":: WARNING: could not switch display-manager.service to SDDM"
        return 1
    fi
}

restore_display_manager() {
    if [[ -e "$DM_LINK.equisdots-backup" ]]; then
        sudo mv -f "$DM_LINK.equisdots-backup" "$DM_LINK"
        echo ":: restored the previous display manager ($(basename "$(readlink "$DM_LINK")"))"
    fi
}

case "${1:-}" in
    -h|--help)
        usage
        ;;
    --uninstall)
        echo ":: removing the x theme and its sddm config"
        sudo rm -rf "$THEME_DIR"
        sudo rm -f "$CONF_DIR/10-x-theme.conf" "$CONF_DIR/z-disable-virtualkbd.conf"
        restore_display_manager
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
        select_display_manager
        echo ":: theme 'x' installed and selected"
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
