#!/bin/bash

# Конфигурация анимации
ANIMATION_SPEED=10          # символов в секунду
STATE_FILE="/tmp/hyprlock_music_state"
FRAME_FILE="/tmp/hyprlock_music_frame"

get_media() {
    # Ищем активно играющие медиа
    if command -v playerctl &> /dev/null; then
        players=$(playerctl --list-all 2>/dev/null)
        
        for player in $players; do
            status=$(playerctl --player="$player" status 2>/dev/null)
            
            if [ "$status" = "Playing" ]; then
                title=$(playerctl --player="$player" metadata title 2>/dev/null)
                artist=$(playerctl --player="$player" metadata artist 2>/dev/null)
                
                if [ -n "$title" ] && [ "$title" != "No player could handle this command" ]; then
                    if [ ${#title} -gt 30 ]; then
                        title="${title:0:27}..."
                    fi
                    
                    if [ -n "$artist" ] && [ "$artist" != "No player could handle this command" ]; then
                        if [ ${#artist} -gt 20 ]; then
                            artist="${artist:0:17}..."
                        fi
                        echo "󰝚 $artist - $title"
                    else
                        echo "󰝚 $title"
                    fi
                    exit 0
                fi
            fi
        done
    fi
    
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
    
    echo ""
}

# Функция для генерации случайного символа из множества Unicode
get_random_char() {
    # Определяем разные диапазоны Unicode для разнообразия
    local ranges=(
        # Основная латиница
        "65 90"      # A-Z
        "97 122"     # a-z
        "48 57"      # 0-9
        
        # Кириллица
        "1040 1103"  # А-я (русские буквы)
        
        # Греческий
        "913 937"    # Α-Ω
        "945 969"    # α-ω
        
        # Математические символы
        "8704 8959"  # математические операторы
        
        # Блоки и рамки
        "9472 9599"  # линии и рамки
        
        # Восточные символы (выборочно)
        "19968 19999" # несколько китайских иероглифов
        "12352 12447" # хирагана
        
        # Дополнительные символы
        "33 47"      # !"#$%&'()*+,-./
        "58 64"      # :;<=>?@
        "91 96"      # [\]^_`
        "123 126"    # {|}~
        
        # Геометрические фигуры
        "9632 9727"  # геометрические фигуры
        
        # Символы валют
        "8352 8399"  # символы валют
        
        # Стрелки
        "8592 8639"  # стрелки
    )
    
    # Выбираем случайный диапазон
    local range_idx=$((RANDOM % ${#ranges[@]}))
    local range=(${ranges[$range_idx]})
    local start=${range[0]}
    local end=${range[1]}
    
    # Генерируем случайный код в этом диапазоне
    local code=$((start + RANDOM % (end - start + 1)))
    
    # Преобразуем код в символ (работает в bash 4.2+)
    printf "\\u$(printf '%04x' "$code")"
}

# Функция для создания анимированной строки
animate_text() {
    local target_text="$1"
    local target_len=${#target_text}
    
    # Читаем предыдущее состояние
    if [ -f "$STATE_FILE" ] && [ -f "$FRAME_FILE" ]; then
        local prev_text=$(head -n1 "$STATE_FILE" 2>/dev/null || echo "")
        local prev_frame=$(head -n1 "$FRAME_FILE" 2>/dev/null || echo "0")
        prev_frame=${prev_frame:-0}
    else
        local prev_text=""
        local prev_frame=0
    fi
    
    # Если текст изменился или отсутствует, начинаем заново
    if [ "$prev_text" != "$target_text" ] || [ -z "$target_text" ]; then
        if [ -z "$target_text" ]; then
            rm -f "$STATE_FILE" "$FRAME_FILE" 2>/dev/null
            echo ""
            return
        fi
        
        echo "$target_text" > "$STATE_FILE"
        echo "0" > "$FRAME_FILE"
        
        # Первый кадр: только первый символ + случайные
        result=""
        for ((i=0; i<target_len; i++)); do
            if [ $i -eq 0 ]; then
                result="${result}${target_text:0:1}"
            else
                result="${result}$(get_random_char)"
            fi
        done
        echo "1" > "$FRAME_FILE"
        echo "$result"
        return
    fi
    
    # Если анимация завершена
    if [ $prev_frame -ge $target_len ]; then
        echo "$target_text"
        return
    fi
    
    # Генерируем следующий кадр
    result=""
    local new_frame=$prev_frame
    
    # Каждый вызов продвигаем анимацию на несколько символов
    for ((i=0; i<target_len; i++)); do
        if [ $i -lt $prev_frame ]; then
            # Уже анимированные символы
            result="${result}${target_text:i:1}"
        elif [ $i -eq $prev_frame ]; then
            # Новый символ, который сейчас станет правильным
            result="${result}${target_text:i:1}"
            new_frame=$((new_frame + 1))
        else
            # Случайные символы для остальной части
            result="${result}$(get_random_char)"
        fi
    done
    
    # Сохраняем прогресс
    echo "$new_frame" > "$FRAME_FILE"
    echo "$result"
}

# Основная логика
current_media=$(get_media)

# Для отладки: можно записывать в лог
# echo "$(date): $current_media" >> /tmp/hyprlock_debug.log

if [ -n "$current_media" ]; then
    animated_output=$(animate_text "$current_media")
    echo "$animated_output"
else
    rm -f "$STATE_FILE" "$FRAME_FILE" 2>/dev/null
    echo ""
fi
