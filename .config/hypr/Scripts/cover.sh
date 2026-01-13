#!/bin/bash

# Путь для сохранения обложки
COVER_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/media_covers"
COVER_PATH="$COVER_DIR/current_cover.jpg"

# Создаем директорию
mkdir -p "$COVER_DIR"

# Функция для извлечения обложки
extract_cover() {
    # Playerctl (для большинства плееров: Spotify, Chrome, Firefox)
    if command -v playerctl &> /dev/null; then
        players=$(playerctl --list-all 2>/dev/null)
        
        for player in $players; do
            status=$(playerctl --player="$player" status 2>/dev/null)
            
            if [ "$status" = "Playing" ]; then
                # Получаем URL обложки через метаданные
                cover_url=$(playerctl --player="$player" metadata mpris:artUrl 2>/dev/null)
                
                if [ -n "$cover_url" ] && [ "$cover_url" != "No player could handle this command" ]; then
                    # Если URL локальный файл
                    if [[ "$cover_url" == file://* ]]; then
                        local_path="${cover_url#file://}"
                        cp -f "$local_path" "$COVER_PATH" 2>/dev/null && echo "$COVER_PATH" && exit 0
                    # Если HTTP URL
                    elif [[ "$cover_url" == http* ]]; then
                        if command -v curl &> /dev/null; then
                            curl -s -L -o "$COVER_PATH" "$cover_url" 2>/dev/null && echo "$COVER_PATH" && exit 0
                        elif command -v wget &> /dev/null; then
                            wget -q -O "$COVER_PATH" "$cover_url" 2>/dev/null && echo "$COVER_PATH" && exit 0
                        fi
                    fi
                fi
            fi
        done
    fi
    
    # MPD (Music Player Daemon)
    if command -v mpc &> /dev/null && timeout 0.5 mpc status &> /dev/null; then
        if mpc status 2>/dev/null | grep -q "\[playing\]"; then
            current_file=$(mpc --format "%file%" current 2>/dev/null)
            
            if [ -n "$current_file" ]; then
                # Извлекаем обложку из аудиофайла с помощью ffmpeg
                if command -v ffmpeg &> /dev/null; then
                    music_dir=$(mpc --format "%file%" current | sed 's|/[^/]*$||')
                    full_path="$HOME/Music/$current_file"  # Стандартный путь MPD
                    
                    # Пробуем разные способы:
                    
                    # 1. Встроенная обложка в файле
                    ffmpeg -i "$full_path" -an -vcodec copy "$COVER_PATH" 2>/dev/null
                    
                    # 2. Ищем cover.jpg/png в папке
                    if [ ! -f "$COVER_PATH" ] || [ ! -s "$COVER_PATH" ]; then
                        cover_file=$(find "$(dirname "$full_path")" -maxdepth 1 \
                            -name "cover.jpg" -o \
                            -name "cover.png" -o \
                            -name "*.jpg" -o \
                            -name "*.png" | head -1)
                        
                        if [ -f "$cover_file" ]; then
                            cp -f "$cover_file" "$COVER_PATH" 2>/dev/null && echo "$COVER_PATH" && exit 0
                        fi
                    else
                        echo "$COVER_PATH" && exit 0
                    fi
                fi
            fi
        fi  # Закрываем if для mpc status - здесь был лишний done
    fi
    
    # Если ничего не нашли - пробуем D-Bus напрямую
    if command -v dbus-send &> /dev/null; then
        # Для Firefox/Chrome
        dbus_output=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.firefox \
            /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get \
            string:org.mpris.MediaPlayer2.Player string:Metadata 2>/dev/null)
        
        if [ -z "$dbus_output" ]; then
            dbus_output=$(dbus-send --print-reply --session --dest=org.mpris.MediaPlayer2.chrome \
                /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get \
                string:org.mpris.MediaPlayer2.Player string:Metadata 2>/dev/null)
        fi
        
        # Парсим вывод D-Bus для поиска обложки
        cover_url=$(echo "$dbus_output" | grep -oP 'artUrl.*variant.*string "\K[^"]+' | head -1)
        
        if [ -n "$cover_url" ]; then
            if [[ "$cover_url" == file://* ]]; then
                local_path="${cover_url#file://}"
                cp -f "$local_path" "$COVER_PATH" 2>/dev/null && echo "$COVER_PATH" && exit 0
            elif [[ "$cover_url" == http* ]]; then
                if command -v curl &> /dev/null; then
                    curl -s -L -o "$COVER_PATH" "$cover_url" 2>/dev/null && echo "$COVER_PATH" && exit 0
                fi
            fi
        fi
    fi
    
    # Если обложка не найдена - возвращаем путь к заглушке
    echo ""
}

# Основной вызов
extract_cover
