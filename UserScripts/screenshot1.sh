#!/bin/bash
# ~/.config/hypr/userscripts/screenshot.sh
FILE="$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"

# Режим по умолчанию - область
MODE=${1:-area}

case "$MODE" in
    "window")
        # Скриншот активного окна
        grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" "$FILE"
        ;;
    "area")
        # Скриншот области (как было)
        grim -g "$(slurp)" "$FILE"
        ;;
esac

# Копируем в буфер если файл создан
[ -f "$FILE" ] && wl-copy < "$FILE"
