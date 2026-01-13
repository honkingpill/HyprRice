#!/usr/bin/env bash

# Конфигурация
STATE_FILE="$HOME/.config/hypr/window_state"
HYPRCTL=$(which hyprctl)

# Дефолтные размеры (используются если не переданы аргументы)
DEFAULT_WIDTH=400
DEFAULT_HEIGHT=400

# Проверяем наличие hyprctl
if [ -z "$HYPRCTL" ]; then
    echo "Ошибка: hyprctl не найден" >&2
    exit 1
fi

# Обработка аргументов
if [ $# -eq 1 ]; then
    # Один аргумент - квадратное окно
    TARGET_WIDTH="$1"
    TARGET_HEIGHT="$1"
elif [ $# -eq 2 ]; then
    # Два аргумента - ширина и высота
    TARGET_WIDTH="$1"
    TARGET_HEIGHT="$2"
elif [ $# -eq 0 ]; then
    # Без аргументов - используем дефолтные значения
    TARGET_WIDTH="$DEFAULT_WIDTH"
    TARGET_HEIGHT="$DEFAULT_HEIGHT"
else
    echo "Использование: $0 [ширина] [высота]" >&2
    echo "Примеры:" >&2
    echo "  $0            # 400x400" >&2
    echo "  $0 500        # 500x500" >&2
    echo "  $0 400 600    # 400x600" >&2
    exit 1
fi

# Проверяем, что аргументы - числа
if ! [[ "$TARGET_WIDTH" =~ ^[0-9]+$ ]] || ! [[ "$TARGET_HEIGHT" =~ ^[0-9]+$ ]]; then
    echo "Ошибка: аргументы должны быть целыми числами" >&2
    exit 1
fi

# Функция для получения данных активного окна
get_active_window() {
    $HYPRCTL activewindow -j | jq -r '.address, .class, .title, .at[0], .at[1], .size[0], .size[1]'
}

# Читаем сохраненное состояние
if [ -f "$STATE_FILE" ]; then
    saved_data=$(cat "$STATE_FILE")
    # Разделяем строку на массив, сохраняя пробелы в названиях окон
    IFS=$'\n' read -d '' -r -a saved <<< "$saved_data"
else
    saved=()
fi

# Получаем текущее активное окно
current_str=$(get_active_window)
IFS=$'\n' read -d '' -r -a current <<< "$current_str"

current_address="${current[0]}"
current_class="${current[1]}"
current_title="${current[2]}"
current_x="${current[3]}"
current_y="${current[4]}"
current_width="${current[5]}"
current_height="${current[6]}"

# Создаем уникальный ключ для окна с учетом целевых размеров
# Это позволяет иметь разные сохраненные состояния для разных целевых размеров
WINDOW_KEY="${current_address}:${TARGET_WIDTH}x${TARGET_HEIGHT}"

# Проверяем, сохранено ли состояние для текущего окна и целевых размеров
if [ ${#saved[@]} -ge 8 ]; then
    saved_key="${saved[0]}"
    saved_address="${saved[1]}"
    saved_class="${saved[2]}"
    saved_title="${saved[3]}"
    
    # Проверяем, что это то же окно с теми же целевыми размерами
    if [ "$WINDOW_KEY" = "$saved_key" ] || \
       ([ "$current_class" = "$saved_class" ] && \
        [ "$current_title" = "$saved_title" ] && \
        [ "${saved[0]}" = "$WINDOW_KEY" ]); then
        
        # Это окно уже уменьшено - восстанавливаем размер
        saved_x="${saved[4]}"
        saved_y="${saved[5]}"
        saved_width="${saved[6]}"
        saved_height="${saved[7]}"
        
        # Восстанавливаем размер и позицию
        $HYPRCTL dispatch movewindowpixel exact $saved_x $saved_y,address:$current_address
        $HYPRCTL dispatch resizewindowpixel exact $saved_width $saved_height,address:$current_address
        
        # Удаляем сохраненное состояние для этих размеров
        # Создаем временный файл без этой записи
        if [ -f "$STATE_FILE" ]; then
            grep -v "^${WINDOW_KEY}" "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null || true
            mv "${STATE_FILE}.tmp" "$STATE_FILE"
            # Если файл пустой, удаляем его
            [ -s "$STATE_FILE" ] || rm -f "$STATE_FILE"
        fi
        
        exit 0
    fi
fi

# Если мы здесь, значит нужно уменьшить окно до целевых размеров
# Сохраняем текущее состояние с ключом
{
    echo "$WINDOW_KEY"
    echo "${current_str}"
} > "$STATE_FILE"

# Вычисляем центр окна для позиционирования
center_x=$((current_x + current_width / 2))
center_y=$((current_y + current_height / 2))

# Вычисляем новые координаты для минимизированного окна (центрирование)
new_x=$((center_x - TARGET_WIDTH / 2))
new_y=$((center_y - TARGET_HEIGHT / 2))

# Устанавливаем целевой размер
$HYPRCTL dispatch resizewindowpixel exact $TARGET_WIDTH $TARGET_HEIGHT,address:$current_address

# Перемещаем в вычисленную позицию
$HYPRCTL dispatch movewindowpixel exact $new_x $new_y,address:$current_address
