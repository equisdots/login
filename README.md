# login

Minimal static login theme for the [equisdots](https://github.com/equisdots)
desktop (SDDM greeter).

Version: **0.1.0** · License: MIT

## Design

Black screen. Only the remembered user and a password field:

- the **last logged-in user** is shown as plain text (SDDM remembers it);
- the password field is a **white underline** that expands from the center
  when focused;
- below, centered: a **session picker** (glyph + session name, minimal popup,
  last session preselected) and **power off / reboot** as small circular
  glyph buttons;
- monochrome, no images, no palette dependency;
- `Hack Nerd Font` for text and glyphs.

Animations (all local, no scripting):

- soft intro: the fields fade in and slide up;
- underline: grows and brightens on focus;
- failed login: shake + red underline + small `login failed` note;
- user switch (`Tab` / `Backtab`): cross-fade of the fields;
- subtle color fades on every control hover.

## Why static

The old palette-synced theme needed writes under `/usr/share/sddm/themes` at
runtime, which meant sudo calls from hooks and a real risk of PAM lockouts
(`pam_faillock`). This theme is installed **once** and never writes again:

- no palette/wallpaper sync, no `Colors.qml`, no background image;
- runtime sudo: none;
- conflicts handled at install: `theme.conf.user` is parked as `.bak`, the
  on-screen keyboard is disabled.

## Install

```sh
./install.sh              # one-time sudo: theme + sddm config
./install.sh --uninstall  # remove the theme and its sddm config
```

The installer copies the theme to `/usr/share/sddm/themes/x`, selects it in
`/etc/sddm.conf.d/10-x-theme.conf` and removes leftovers from the previous
version.

It also makes sure **SDDM is the active display manager**: if another DM
(`plasmalogin`, GDM, LightDM, Ly, greetd...) owns
`/etc/systemd/system/display-manager.service`, the previous symlink is kept at
`display-manager.service.equisdots-backup` and the link is switched to SDDM
(the other DM is disabled). `--uninstall` restores it. The theme can only be
shown when SDDM is the one greeting you.

## Structure

```
login/
  install.sh               installer (one-time sudo)
  z-disable-virtualkbd.conf  sddm fragment that disables the virtual keyboard
  theme/x/                 the SDDM theme (Qt6)
    Main.qml               the whole UI + animations
    metadata.desktop       theme metadata
    theme.conf             [General] InputMethod= (no background)
```

## Integration

`dots install` clones this repo; `dots system` runs the hyprland installer,
which delegates the SDDM theme to this repo's `install.sh` (sibling
checkout). The hyprland `uninstall.sh` delegates here too.

## License

AGPL-3.0-or-later — see [LICENSE](LICENSE). Copyright (C) 2026 xscriptor <x@xscriptor.com>.

This repository is licensed under the GNU Affero General Public License, version 3 or any later version. If you modify the software and let users interact with it over a network, you must offer them the corresponding source.

Releases published before 2026-11-13 were distributed under the MIT License and remain available under those terms.

Third-party components, fonts, icons, images, sounds, vendored code and other assets keep their original licenses and are not covered by this license. See THIRD-PARTY.md / CREDITS.md where present.
