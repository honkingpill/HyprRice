#!/bin/bash
# install.sh

echo "=== Установка Hyprlock Music Plugin ==="

# Переходим в папку скрипта
cd "$(dirname "$0")"

echo "1. Проверка зависимостей..."

# Проверяем gcc
if ! command -v gcc &> /dev/null; then
    echo "❌ Ошибка: gcc не установлен"
    echo "Установите: sudo pacman -S gcc (Arch) или sudo apt install gcc (Debian)"
    exit 1
fi

# Проверяем playerctl
if ! command -v playerctl &> /dev/null; then
    echo "⚠️  Предупреждение: playerctl не установлен"
    echo "Рекомендуется: sudo pacman -S playerctl (Arch) или sudo apt install playerctl (Debian)"
    echo "Продолжаем без playerctl..."
fi

# Проверяем mpc
if ! command -v mpc &> /dev/null; then
    echo "⚠️  Предупреждение: mpc (MPD клиент) не установлен"
fi

echo "✅ Зависимости проверены"

echo ""
echo "2. Компиляция плагина..."

# Очистка предыдущей сборки
if [ -f "Makefile" ]; then
    make clean 2>/dev/null || true
fi

# Компиляция
make

if [ $? -ne 0 ]; then
    echo "❌ Ошибка компиляции!"
    echo "Проверьте наличие gcc и исходного кода"
    exit 1
fi

echo "✅ Компиляция успешна"

echo ""
echo "3. Тестирование..."

# Быстрая проверка
echo "Тестовый запуск (5 секунд)..."
timeout 5 ./hyprlock-music-plugin &
TEST_PID=$!
sleep 1
echo "Если выше нет ошибок - плагин работает"

echo ""
echo "4. Установка в систему..."

# Спрашиваем подтверждение
read -p "Установить в /usr/local/bin? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo make install
    if [ $? -eq 0 ]; then
        echo "✅ Установка завершена"
    else
        echo "⚠️  Ошибка установки, пробуем вручную..."
        sudo cp hyprlock-music-plugin /usr/local/bin/ 2>/dev/null || {
            echo "Попробуйте: sudo cp hyprlock-music-plugin /usr/local/bin/"
        }
    fi
else
    echo "⏭️  Пропускаем установку в систему"
fi

echo ""
echo "5. Настройка Hyprlock..."

CONFIG_DIR="$HOME/.config/hypr"
CONFIG_FILE="$CONFIG_DIR/hyprlock.conf"

# Проверяем существование конфига
if [ ! -f "$CONFIG_FILE" ]; then
    echo "⚠️  Файл $CONFIG_FILE не найден"
    echo "Создайте его вручную"
else
    # Проверяем, есть ли уже конфигурация плагина
    if grep -q "hyprlock-music-plugin" "$CONFIG_FILE"; then
        echo "✅ Конфигурация уже добавлена в hyprlock.conf"
    else
        echo ""
        echo "Добавьте следующий блок в $CONFIG_FILE:"
        echo "========================================="
        cat << 'EOF'
# CURRENT SONG (Music Plugin)
label {
    monitor =
    text = exec:/usr/local/bin/hyprlock-music-plugin
    color = $foreground
    font_size = 18
    font_family = Metropolis Light, Font Awesome 6 Free Solid
    position = 0, 50
    halign = center
    valign = bottom
}
EOF
        echo "========================================="
        
        # Предлагаем добавить автоматически
        read -p "Добавить автоматически? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "" >> "$CONFIG_FILE"
            cat << 'EOF' >> "$CONFIG_FILE"
# CURRENT SONG (Music Plugin)
label {
    monitor =
    text = exec:/usr/local/bin/hyprlock-music-plugin
    color = $foreground
    font_size = 18
    font_family = Metropolis Light, Font Awesome 6 Free Solid
    position = 0, 50
    halign = center
    valign = bottom
}
EOF
            echo "✅ Конфигурация добавлена"
        fi
    fi
fi

echo ""
echo "=== Установка завершена ==="
echo ""
echo "Инструкция по использованию:"
echo "1. Запустите музыку в любом плеере (Spotify, Firefox, VLC и т.д.)"
echo "2. Активируйте Hyprlock (обычно Win+L или через hyprlock)"
echo "3. Внизу экрана должна появиться анимация с названием трека"
echo ""
echo "Полезные команды:"
echo "• Тестовый запуск: ./hyprlock-music-plugin"
echo "• Перекомпиляция: make clean && make"
echo "• Удаление: sudo make uninstall"
