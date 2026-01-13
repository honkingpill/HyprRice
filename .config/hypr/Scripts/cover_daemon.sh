#!/bin/bash
# cover_simple_daemon.sh - простой демон для обложки

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COVER_SCRIPT="$SCRIPT_DIR/cover.sh"
INTERVAL=5

# Проверяем наличие скрипта
if [ ! -f "$COVER_SCRIPT" ]; then
    echo "Ошибка: скрипт обложки не найден: $COVER_SCRIPT"
    exit 1
fi

if [ ! -x "$COVER_SCRIPT" ]; then
    chmod +x "$COVER_SCRIPT"
fi

echo "Демон обложки запущен. Интервал: $INTERVAL секунд"
echo "Для остановки нажмите Ctrl+C"

# Основной цикл
while true; do
    "$COVER_SCRIPT" > /dev/null 2>&1
    sleep $INTERVAL
done
