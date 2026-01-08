#!/bin/bash

# Define colors for better output visibility
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}--- Starting Arch Linux System Cleanup ---${NC}"

# 1. Remove Orphan Packages (Pacman)
echo -e "\n${YELLOW}1. Searching for orphan packages (Pacman)...${NC}"
# Redirect stderr to avoid "error: no targets specified" showing up if clean
ORPHANS=$(pacman -Qdtq 2>/dev/null)
if [ -n "$ORPHANS" ]; then
    echo -e "${GREEN}Removing orphans...${NC}"
    sudo pacman -Rns $ORPHANS --noconfirm
else
    echo -e "${GREEN}No orphan packages found.${NC}"
fi

# 2. Cleanup unused dependencies with Yay
if command -v yay &> /dev/null; then
    echo -e "\n${YELLOW}2. Cleaning up unused dependencies with Yay...${NC}"
    yay -Yc --noconfirm
else
    echo -e "\n${RED}Yay not found, skipping step 2.${NC}"
fi

# 3. Clean Pacman Package Cache
# Keeps only currently installed versions (Safe)
echo -e "\n${YELLOW}3. Cleaning Pacman package cache...${NC}"
sudo pacman -Sc --noconfirm

# 4. Clean Yay (AUR) Cache
if command -v yay &> /dev/null; then
    echo -e "\n${YELLOW}4. Cleaning Yay/AUR cache...${NC}"
    # Sometimes yay interactive needs explicit confirmation even with flag, 
    # but we force clean cache and untracked files
    yay -Scc --noconfirm
    
    # EXTRA: Force remove yay cache folder if it persists (aggressive but effective)
    # rm -rf ~/.cache/yay
fi

# 5. Clean System Logs (Journald)
echo -e "\n${YELLOW}5. Vacuuming system logs (older than 2 weeks)...${NC}"
sudo journalctl --vacuum-time=2weeks

# 6. Clean User Cache (Thumbnails & Trash)
echo -e "\n${YELLOW}6. Cleaning user cache (Thumbnails & Trash)...${NC}"
rm -rf ~/.cache/thumbnails/*
# --- Empty the Trash ---
rm -rf ~/.local/share/Trash/*
echo -e "${GREEN}Trash emptied.${NC}"

echo -e "\n${GREEN}--- Cleanup process completed successfully! ---${NC}"