#!/bin/bash

get_media() {
    # Ищем активно играющие медиа
    if command -v playerctl &> /dev/null; then
        # Получаем список всех активных плееров
        players=$(playerctl --list-all 2>/dev/null)
        
        for player in $players; do
            status=$(playerctl --player="$player" status 2>/dev/null 2>/dev/null)
            
            # Только играющие
            if [ "$status" = "Playing" ]; then
                title=$(playerctl --player="$player" metadata title 2>/dev/null 2>/dev/null)
                artist=$(playerctl --player="$player" metadata artist 2>/dev/null 2>/dev/null)
                
                if [ -n "$title" ] && [ "$title" != "No player could handle this command" ]; then
                    # Обрезаем длинные строки
                   # if [ ${#title} -gt 30 ]; then
                   #     title="${title:0:27}..."
                   # fi
                    
                    if [ -n "$artist" ] && [ "$artist" != "No player could handle this command" ]; then
                   #     if [ ${#artist} -gt 20 ]; then
                   #         artist="${artist:0:17}..."
                   #     fi
                        echo "󰝚 $artist - $title"
                    else
                        echo "󰝚 $title"
                    fi
                    exit 0
                fi
            fi
        done
    fi
    
    # Проверяем MPD
    if command -v mpc &> /dev/null && timeout 0.5 mpc status &> /dev/null; then
        if mpc status 2>/dev/null | grep -q "\[playing\]"; then
            title=$(mpc current 2>/dev/null)
            if [ -n "$title" ]; then
                if [ ${#title} -gt 35 ]; then
                    title="${title:0:32}..."
                fi
                echo "󰝚 $title"
                exit 0
            fi
        fi
    fi
    
    # Ничего не играет
    echo ""
}

get_media
