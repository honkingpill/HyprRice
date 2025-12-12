#!/bin/bash
# ~/.config/hypr/userscripts/screenshot.sh

# Делаем скриншот области и сохраняем в файл
FILENAME="$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"

if grim -g "$(slurp)" "$FILENAME"; then
    # Копируем этот файл в буфер обмена
    wl-copy < "$FILENAME"
    
fi

