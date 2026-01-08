# Switchblade 🗡️

A Swiss Army Knife menu for Rofi (App launcher, Wallpaper, Package manager, System Cleanup and much more).

## Features

- **App Launcher**: Cached for speed.
- **Wallpaper Manager**: Selects, applies via `matugen` and updates SDDM theme.
- **Package Manager**: Unified search/install/remove for Pacman, Yay, and Flatpak.
- **Automated System Cleanup**: One-click maintenance script that removes orphan packages (pacman/yay), clears package caches, vacuums system logs (journald), and empties the Trash/Thumbnails to free up disk space.
- **Reload UI**: Instantly reload SwayNC and Waybar configurations without restarting the session.

## Requirements

Before using, ensure you have these installed:

### Required

- **libnotify** (for system notifications)
- [matugen](https://github.com/InioX/matugen) (for color generation)
- **polkit** (required for SDDM permission escalation)
- [rofi](https://github.com/davatorium/rofi)
- [yay](https://github.com/Jguer/yay)

### Optional

- [flatpak](https://flatpak.org/)
- [swaync](https://github.com/ErikReider/SwayNotificationCenter)
- [waybar](https://github.com/Alexays/Waybar)

## Installation

1. Clone the repo:

   ```bash
   git clone https://github.com/ChristianAlessandri/switchblade.git ~/switchblade
   ```

2. Make it executable:

   ```bash
   chmod +x ~/switchblade/switchblade.sh ~/switchblade/scripts/*.sh
   ```

## Configuration

### 1. Script Variables

Open `switchblade.sh` and edit the top variables to match your system:

```bash
WALL_DIR="$HOME/Pictures/Wallpapers"      # Your wallpaper folder
SDDM_THEME_DIR="/usr/share/sddm/themes/..." # Your SDDM theme path
```

### 2. Theme Integration (Matugen)

To enable dynamic theming for apps (Waybar, Kitty, etc.) and SDDM, you need to configure Matugen. **👉 Please read the [Matugen Setup Guide](./matugen/README.md) inside the `matugen` folder.**

It explains how to:

- Copy the config files.
- Set up the `sudoers` permission for the login screen.
- **Configure your SDDM theme to use the dynamic wallpaper.**

---

## Usage

Add this to your `hyprland.conf`:

1. **Open the menu**:

   ```bash
   bind = $mainMod, TAB, exec, /home/$USER/switchblade/switchblade.sh
   ```

2. **Fast UI Reload**

   Bypass the menu to instantly reload Waybar and SwayNC:

   ```bash
   bind = $mainMod, R, exec, ~/switchblade/switchblade.sh --reload
   ```

## Notes ⚠️

- **Cleanup Safety**: The cleanup script runs in non-interactive mode (`--noconfirm`) for a seamless experience. It is designed to be safe, but please review `scripts/clean.sh` if you want to customize the aggressive cache cleaning.
- **Wallpapers**: Ensure all backgrounds are in `.jpg` format for SDDM compatibility.

## License

This project is distributed under the **GNU GPLv3** license.

Copyright (C) 2026 **Christian Alessandri**.

See the [LICENSE](./LICENSE) file for details.
