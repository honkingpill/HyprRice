# Создай файл ~/.config/hypr/userscripts/debug.sh
#!/bin/bash
echo "Скрипт запущен в $(date)" > /tmp/hypr-debug.log
echo "Аргументы: $@" >> /tmp/hypr-debug.log
notify-send "Debug" "Скрипт работает!" 2>/dev/null || echo "notify-send не работает" >> /tmp/hypr-debug.log
