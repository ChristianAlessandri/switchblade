#!/bin/bash

# Find where the file is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# --- CONFIGURATIONS ---
WALL_DIR="$HOME/Pictures/Wallpapers"
SDDM_THEME_DIR="/usr/share/sddm/themes/your-sddm"
SDDM_WALL_FILE="current.jpg"

CLEAN_SCRIPT="$SCRIPT_DIR/clean.sh"
CACHE_FILE="$SCRIPT_DIR/cache.csv" # Better to keep it here than in /tmp if you want it to persist after reboot

# Custom Menu Labels
MAIN_WALL="Change Theme"
MAIN_PKG="Manage Packages"
MAIN_CLEAN="Clean System"

# --- TERMINAL DETECTION ---
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

# --- GENERATE APP CACHE ---
generate_app_list() {
    if [ ! -s "$CACHE_FILE" ]; then
        find /usr/share/applications "$HOME/.local/share/applications" -name "*.desktop" 2>/dev/null | while read -r file; do
            name=$(grep -m 1 "^Name=" "$file" | cut -d= -f2-)
            exec_cmd=$(grep -m 1 "^Exec=" "$file" | cut -d= -f2-)
            icon=$(grep -m 1 "^Icon=" "$file" | cut -d= -f2-)
            if [ -n "$name" ] && [ -n "$exec_cmd" ]; then
                exec_clean=$(echo "$exec_cmd" | sed 's/ %[a-zA-Z]//g')
                echo "${name}|${exec_clean}|${icon}" >> "$CACHE_FILE"
            fi
        done
    fi
}

# --- MAIN MENU ---
print_menu_options() {
    printf "%s\0icon\x1fpreferences-desktop-wallpaper\n" "$MAIN_WALL"
    printf "%s\0icon\x1fpackage-x-generic\n" "$MAIN_PKG"
    printf "%s\0icon\x1fsystem-file-manager\n" "$MAIN_CLEAN"
    if [ -f "$CACHE_FILE" ]; then
        awk -F'|' '{printf "%s\0icon\x1f%s\n", $1, $3}' "$CACHE_FILE"
    fi
}

# --- ACTION FUNCTIONS ---

change_wallpaper() {
    file_list=("$WALL_DIR"/*)
    selected_name=$(
        for file in "${file_list[@]}"; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                name="${filename%.*}"
                printf "%s\0icon\x1f%s\n" "$name" "$file"
            fi
        done | rofi -dmenu -p "Wallpaper" -show-icons -theme-str 'window {width: 40%;}' -format s
    )

    # If the user presses Esc here, selected_name is empty, the function ends and returns to the menu
    if [ -n "$selected_name" ]; then
        for file in "${file_list[@]}"; do
            if [[ "$file" == *"$selected_name"* ]]; then
                matugen image "$file"
                if [ -d "$SDDM_THEME_DIR" ]; then
                    pkexec cp "$file" "$SDDM_THEME_DIR/$SDDM_WALL_FILE"
                fi
                break
            fi
        done
    fi
}

manage_packages() {
    SRC_PACMAN="Pacman"
    SRC_YAY="Yay"
    SRC_FLATPAK="Flatpak"
    
    # If the user presses Esc here, source is empty, return and go back to the Main Loop
    source=$(printf "%s\n%s\n%s" "$SRC_PACMAN" "$SRC_YAY" "$SRC_FLATPAK" | rofi -dmenu -p "Source" -theme-str 'window {width: 20%;}')
    
    [ -z "$source" ] && return

    case "$source" in
        "$SRC_PACMAN") cmd="pacman -Qqe"; remove="sudo pacman -Rns" ;;
        "$SRC_YAY") cmd="pacman -Qmqe"; remove="yay -Rns" ;;
        "$SRC_FLATPAK") cmd="flatpak list --app --columns=application"; remove="flatpak uninstall" ;;
        *) return ;;
    esac

    # If the user presses Esc here, pkg is empty, the if block is skipped, function ends -> Main Loop
    pkg=$(eval "$cmd" | rofi -dmenu -i -p "Search $source")
    
    if [ -n "$pkg" ]; then
        action=$(printf "Info\nUninstall" | rofi -dmenu -p "$pkg" -theme-str 'window {width: 20%; height: 15%;}')
        case "$action" in
            "Info")
                if [ "$source" == "Flatpak" ]; then flatpak info "$pkg"; else pacman -Qi "$pkg" || yay -Qi "$pkg"; fi | rofi -dmenu -lines 20 -theme-str 'window {width: 50%;}' 
                ;;
            "Uninstall") 
                $TERM_CMD bash -c "$remove $pkg; read -p 'Press Enter...'" 
                ;;
        esac
    fi
}

run_clean() {
    if [ -f "$CLEAN_SCRIPT" ]; then
        $TERM_CMD bash "$CLEAN_SCRIPT"
    else
        rofi -e "Script not found: $CLEAN_SCRIPT"
    fi
}

# --- MAIN LOOP ---

generate_app_list

while true; do
    # Direct pipe to rofi
    SELECTION=$(print_menu_options | rofi -dmenu -i -p "Switchblade" -show-icons -theme-str 'window {width: 35%;}' -format s)

    # If the user presses Esc in the MAIN MENU, exit the script
    if [ -z "$SELECTION" ]; then
        exit 0
    fi

    case "$SELECTION" in
        "$MAIN_WALL")
            change_wallpaper
            ;;
        "$MAIN_PKG")
            manage_packages
            ;;
        "$MAIN_CLEAN")
            run_clean
            ;;
        *)
            # App Management
            CMD=$(grep -m 1 "^${SELECTION}|" "$CACHE_FILE" | cut -d'|' -f2)
            
            if [ -n "$CMD" ]; then
                nohup $CMD >/dev/null 2>&1 &
                exit 0 # If you launch an app, you want the menu to really close
            fi
            ;;
    esac
done