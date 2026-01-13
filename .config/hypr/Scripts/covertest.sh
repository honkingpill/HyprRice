#!/bin/bash

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/media_covers"
COVER_PATH="$CACHE_DIR/current_cover.jpg"
mkdir -p "$CACHE_DIR"

# Быстрая проверка плеера
get_media_info() {
    # Проверяем кэш (5 секунд)
    if [ -f "$COVER_PATH" ] && [ $(($(date +%s) - $(stat -c %Y "$COVER_PATH"))) -lt 5 ]; then
        [ -f "$COVER_PATH" ] && echo "IMAGE:$COVER_PATH"
        return
    fi
    
    # 1. Playerctl (самый быстрый)
    if command -v playerctl &> /dev/null; then
        players=$(timeout 1 playerctl --list-all 2>/dev/null)
        
        for player in $players; do
            status=$(timeout 0.5 playerctl --player="$player" status 2>/dev/null)
            
            if [ "$status" = "Playing" ]; then
                # Получаем обложку
                cover_url=$(timeout 0.5 playerctl --player="$player" metadata mpris:artUrl 2>/dev/null)
                
                if [ -n "$cover_url" ] && [[ "$cover_url" != *"No player"* ]]; then
                    # Скачиваем если URL
                    if [[ "$cover_url" == http* ]] && command -v curl &> /dev/null; then
                        timeout 2 curl -s -L -o "$COVER_PATH" "$cover_url" 2>/dev/null
                    elif [[ "$cover_url" == file://* ]]; then
                        cp -f "${cover_url#file://}" "$COVER_PATH" 2>/dev/null
                    fi
                    
                    [ -f "$COVER_PATH" ] && echo "IMAGE:$COVER_PATH" && return
                fi
            fi
        done
    fi
    
    # 2. Если нет обложки, но есть трек - показываем иконку
    if command -v playerctl &> /dev/null; then
        players=$(playerctl --list-all 2>/dev/null | head -1)
        if [ -n "$players" ]; then
            status=$(playerctl --player="$players" status 2>/dev/null)
            if [ "$status" = "Playing" ]; then
                echo "󰝚 $(playerctl --player="$players" metadata title 2>/dev/null | cut -c1-30)"
                return
            fi
        fi
    fi
    
    echo ""  # Пустой вывод если ничего не играет
}

get_media_info
