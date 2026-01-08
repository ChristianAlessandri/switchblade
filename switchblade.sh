#!/bin/bash

# Resolve script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# --- CONFIGURATIONS ---
WALL_DIR="$HOME/Pictures/Wallpapers"
SDDM_THEME_DIR="/usr/share/sddm/themes/your-sddm"
SDDM_WALL_FILE="current.jpg"

CLEAN_SCRIPT="$SCRIPT_DIR/scripts/clean.sh"
RELOAD_SWAYNC_SCRIPT="$SCRIPT_DIR/scripts/reload_swaync.sh"
RELOAD_WAYBAR_SCRIPT="$SCRIPT_DIR/scripts/reload_waybar.sh"

CACHE_FILE="$SCRIPT_DIR/app_cache.csv"

# Directories to scan for applications
APP_DIRS=(
    "/usr/share/applications"
    "$HOME/.local/share/applications"
    "/var/lib/flatpak/exports/share/applications"
    "$HOME/.local/share/flatpak/exports/share/applications"
)

# Custom Menu Labels
MAIN_APPS="App Launcher"
MAIN_WALL="Change Theme"
MAIN_PKG="Manage Packages"
MAIN_CLEAN="Clean System"
MAIN_REFRESH="Force Refresh Cache"
MAIN_RELOAD="Reload UI"

# --- TERMINAL DETECTION ---
# Attempt to detect the preferred terminal emulator
if [ -n "$TERMINAL" ]; then
    TERM_CMD="$TERMINAL -e"
elif command -v xdg-terminal-exec >/dev/null 2>&1; then
    TERM_CMD="xdg-terminal-exec --"
else
    for t in alacritty kitty st gnome-terminal foot xterm konsole terminator; do
        if command -v "$t" >/dev/null 2>&1; then
            TERM_CMD="$t -e"
            break
        fi
    done
fi

# --- APP CACHE GENERATION ---
generate_app_list() {
    local force=$1
    local update_needed=false

    # Check if cache exists or needs updating
    if [ ! -f "$CACHE_FILE" ]; then
        update_needed=true
    elif [ "$force" != "true" ]; then
        changed=$(find "${APP_DIRS[@]}" -maxdepth 1 -newer "$CACHE_FILE" -print -quit 2>/dev/null)
        if [ -n "$changed" ]; then update_needed=true; fi
    else
        update_needed=true
    fi

    # Rebuild cache if necessary by parsing .desktop files
    if [ "$update_needed" = true ]; then
        : > "$CACHE_FILE.tmp"
        for dir in "${APP_DIRS[@]}"; do
            [ -d "$dir" ] || continue
            find "$dir" -name "*.desktop" 2>/dev/null | while read -r file; do
                eval $(awk -F= '
                    /^\[Desktop Entry\]/ { in_entry=1 }
                    /^\[.*\]/ && !/^\[Desktop Entry\]/ { in_entry=0 }
                    in_entry && /^Name=/ { if (!name) name=substr($0, 6) }
                    in_entry && /^Exec=/ { if (!exec) exec=substr($0, 6) }
                    in_entry && /^Icon=/ { if (!icon) icon=substr($0, 6) }
                    in_entry && /^NoDisplay=/ { nodisplay=substr($0, 11) }
                    END {
                        gsub(/"/, "\\\"", name); gsub(/"/, "\\\"", exec); gsub(/"/, "\\\"", icon);
                        print "name=\"" name "\""; print "exec_cmd=\"" exec "\""; print "icon=\"" icon "\""; print "nodisplay=\"" nodisplay "\"";
                    }
                ' "$file")

                if [ "$nodisplay" == "true" ] || [ -z "$name" ] || [ -z "$exec_cmd" ]; then continue; fi
                exec_clean=$(echo "$exec_cmd" | sed -E 's/ %[a-zA-Z]//g' | sed 's/^"//;s/"$//')
                echo "${name}|${exec_clean}|${icon}" >> "$CACHE_FILE.tmp"
            done
        done
        sort -t'|' -u -k1,1 "$CACHE_FILE.tmp" > "$CACHE_FILE"
        rm "$CACHE_FILE.tmp"
    fi
}

# --- MENU GENERATION FUNCTIONS ---
print_buttons() {
    printf "%s\0icon\x1fview-app-grid\n" "$MAIN_APPS"
    printf "%s\0icon\x1fpreferences-desktop-wallpaper\n" "$MAIN_WALL"
    printf "%s\0icon\x1fpackage-x-generic\n" "$MAIN_PKG"
    printf "%s\0icon\x1fsystem-file-manager\n" "$MAIN_CLEAN"
    printf "%s\0icon\x1fsystem-restart\n" "$MAIN_RELOAD"
    printf "%s\0icon\x1fview-refresh\n" "$MAIN_REFRESH"
}

print_apps() {
    if [ -f "$CACHE_FILE" ]; then
        awk -F'|' '{printf "%s\0icon\x1f%s\n", $1, $3}' "$CACHE_FILE"
    fi
}

# --- ACTION FUNCTIONS ---
change_wallpaper() {
    file_list=("$WALL_DIR"/*)
    selected_name=$(
        for file in "${file_list[@]}"; do
            [ -f "$file" ] && printf "%s\0icon\x1f%s\n" "$(basename "${file%.*}")" "$file"
        done | rofi -dmenu -p "Wallpaper" -show-icons -theme-str 'window {width: 40%;}' -format s
    )
    
    # If a wallpaper is selected, apply it. If empty (ESC), return to loop.
    if [ -n "$selected_name" ]; then
        for file in "${file_list[@]}"; do
            if [[ "$file" == *"$selected_name"* ]]; then
                matugen image "$file"
                [ -d "$SDDM_THEME_DIR" ] && pkexec cp "$file" "$SDDM_THEME_DIR/$SDDM_WALL_FILE"
                break
            fi
        done
    fi
}

manage_packages() {
    SRC_PACMAN="Pacman"; SRC_YAY="Yay"; SRC_FLATPAK="Flatpak"
    
    source=$(printf "%s\n%s\n%s" "$SRC_PACMAN" "$SRC_YAY" "$SRC_FLATPAK" | rofi -dmenu -p "Source" -theme-str 'window {width: 20%;} listview {lines: 3;}')
    
    # Return to main loop if cancelled
    [ -z "$source" ] && return

    case "$source" in
        "$SRC_PACMAN") cmd="pacman -Qqe"; remove="sudo pacman -Rns" ;;
        "$SRC_YAY") cmd="pacman -Qmqe"; remove="yay -Rns" ;;
        "$SRC_FLATPAK") cmd="flatpak list --app --columns=application"; remove="flatpak uninstall" ;;
        *) return ;;
    esac

    pkg=$(eval "$cmd" | rofi -dmenu -i -p "Search $source")
    
    # Proceed only if a package was selected
    if [ -n "$pkg" ]; then
        action=$(printf "Info\0icon\x1fdialog-information\nUninstall\0icon\x1fuser-trash\n" | rofi -dmenu -p "$pkg" -show-icons -theme-str 'window {width: 20%;} listview {lines: 2;}')
        
        case "$action" in
            "Info") (if [ "$source" == "Flatpak" ]; then flatpak info "$pkg"; else pacman -Qi "$pkg" || yay -Qi "$pkg"; fi) | rofi -dmenu -p "Info" -lines 20 -theme-str 'window {width: 50%;}' ;;
            "Uninstall") $TERM_CMD bash -c "$remove $pkg; read -p 'Press Enter...'" ;;
        esac
    fi
}

run_clean() {
    if [ -f "$CLEAN_SCRIPT" ]; then $TERM_CMD bash "$CLEAN_SCRIPT"; else rofi -e "Script not found: $CLEAN_SCRIPT"; fi
}

run_reload_ui() {
    [ -f "$RELOAD_SWAYNC_SCRIPT" ] && bash "$RELOAD_SWAYNC_SCRIPT" &
    [ -f "$RELOAD_WAYBAR_SCRIPT" ] && bash "$RELOAD_WAYBAR_SCRIPT" &
}

# --- CLI ARGUMENTS CHECK ---
if [ "$1" == "--reload" ]; then run_reload_ui; exit 0; fi

# --- MAIN LOGIC ---
generate_app_list "false"

# Main Event Loop: ensures user returns to the menu after a submenu action (unless launching an app)
while true; do

    SELECTION=$( (print_buttons; print_apps) | rofi -dmenu -i -p "Switchblade" -show-icons -theme-str 'window {width: 35%;} listview {lines: 6;}' -format s)

    # Exit script if ESC is pressed at the main menu
    if [ -z "$SELECTION" ]; then 
        exit 0
    fi

    case "$SELECTION" in
        "$MAIN_APPS")
            # Open expanded app launcher
            APP_SEL=$(print_apps | rofi -dmenu -i -p "Apps" -show-icons -theme-str 'window {width: 35%;} listview {lines: 15;}' -format s)
            
            # If app selected, launch and exit script
            if [ -n "$APP_SEL" ]; then
                CMD=$(grep -F -m 1 "${APP_SEL}|" "$CACHE_FILE" | cut -d'|' -f2)
                nohup sh -c "$CMD" >/dev/null 2>&1 &
                exit 0
            fi
            # If ESC pressed (APP_SEL empty), loop restarts (returning to main menu)
            ;;
            
        "$MAIN_WALL") change_wallpaper ;; 
        "$MAIN_PKG") manage_packages ;;   
        "$MAIN_CLEAN") run_clean ;;
        "$MAIN_RELOAD") run_reload_ui; exit 0 ;;
        "$MAIN_REFRESH") generate_app_list "true" ;;
        *)
            # Direct search from main menu
            CMD_LINE=$(grep -F -m 1 "${SELECTION}|" "$CACHE_FILE")
            
            if [ -n "$CMD_LINE" ]; then
                CMD=$(echo "$CMD_LINE" | cut -d'|' -f2)
                nohup sh -c "$CMD" >/dev/null 2>&1 &
                exit 0
            else
                # Reload menu on error/mismatch
                continue
            fi
            ;;
    esac
done