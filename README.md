# Switchblade 🔪

A Swiss Army Knife menu for Rofi (Wallpaper, Packages, System Cleanup).

## Features

- **Wallpaper Manager**: Selects, applies via `matugen` and updates SDDM theme.
- **Package Manager**: Unified search/install/remove for Pacman, Yay, and Flatpak.
- **App Launcher**: Cached for speed.
- **Loop Navigation**: Press ESC to go back to the main menu instead of closing.

## Requirements

Before using, ensure you have these installed:

- `rofi` (obviously)
- `matugen` (for color generation)
- `yay` (or another AUR helper)
- `flatpak` (optional)

## Installation

1. Clone the repo:

   ```bash
   git clone [https://github.com/ChristianAlessandri/switchblade.git](https://github.com/ChristianAlessandri/switchblade.git) ~/switchblade
   ```

2. Make it executable and link it to your bin:

   ```bash
   chmod +x ~/switchblade/switchblade.sh
   ln -s ~/switchblade/switchblade.sh ~/.local/bin/switchblade
   ```

## Configuration

Open `switchblade.sh` and edit the top variables to match your system:

```bash
WALL_DIR="$HOME/Pictures/Wallpapers"      # Your wallpaper folder
SDDM_THEME_DIR="/usr/share/sddm/themes/..." # Your SDDM theme path
```

## Usage

**Run from terminal**

```bash
switchblade
```

**Hyprland Keybind**

Add this to your `hyprland.conf`:

```bash
bind = $mainMod, TAB, exec, /home/$USER/.local/bin/switchblade
```

## Notes

- All backgrounds must be in jpg format.
