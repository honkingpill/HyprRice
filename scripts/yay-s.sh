#!/bin/bash

# Проверяем, передан ли аргумент поиска
if [ $# -eq 0 ]; then
    echo "❌ Использование: $0 <поисковый_запрос>"
    echo "Пример: $0 gimp"
    exit 1
fi

search_term="$1"

echo "🔍 Ищем пакеты по запросу: '$search_term'"

# Ищем пакеты через yay
# Используем 2>/dev/null чтобы убрать stderr
results=$(yay -Ss "$search_term" 2>/dev/null)

# Проверяем наличие результатов
if [ -z "$results" ]; then
    echo "❌ Ничего не найдено по запросу '$search_term'"
    exit 1
fi

echo "📦 Найдено $(echo "$results" | wc -l) строк:"
echo "==================="

# Читаем вывод построчно, группируя по пакетам (2 строки: имя + описание)
counter=0
declare -a package_names
declare -a package_descriptions

while IFS= read -r line1 && read -r line2; do
    if [[ -n "$line1" ]]; then
        counter=$((counter + 1))
        
        # Извлекаем имя пакета (формат: "репозиторий/имя версия")
        # Удаляем цветовые коды если есть
        clean_line=$(echo "$line1" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
        
        if [[ "$clean_line" =~ ^([^/]+)/([^[:space:]]+) ]]; then
            repo="${BASH_REMATCH[1]}"
            pkg_name="${BASH_REMATCH[2]}"
            package_names[$counter]="$pkg_name"
            package_descriptions[$counter]="$line2"
            
            # Выводим с номером
            printf "%2d: \033[1;32m%s/%s\033[0m\n" "$counter" "$repo" "$pkg_name"
            printf "    %s\n" "$line2"
        else
            package_names[$counter]="$clean_line"
            package_descriptions[$counter]="$line2"
            printf "%2d: %s\n" "$counter" "$clean_line"
            printf "    %s\n" "$line2"
        fi
    fi
done <<< "$results"

echo "==================="
echo "Введите номера пакетов через пробел (например: 1 3 5):"
read -r choices

# Обрабатываем выбор
selected_names_array=()
for choice in $choices; do
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -le "$counter" ]] && [[ "$choice" -ge 1 ]]; then
        selected_names_array+=("${package_names[$choice]}")
        echo "✓ Выбран: ${package_names[$choice]}"
    else
        echo "⚠ Пропущен неверный номер: $choice"
    fi
done

# Копируем в буфер обмена
if [ ${#selected_names_array[@]} -gt 0 ]; then
    # Объединяем имена пакетов в одну строку через пробел
    selected_names_oneline="${selected_names_array[*]}"
    
    # Пробуем разные способы копирования
    if command -v wl-copy &> /dev/null; then
        echo -n "$selected_names_oneline" | wl-copy
        echo "✅ Имена пакетов скопированы в буфер обмена (Wayland):"
        echo "$selected_names_oneline"
    elif command -v xclip &> /dev/null; then
        echo -n "$selected_names_oneline" | xclip -selection clipboard
        echo "✅ Имена пакетов скопированы в буфер обмена (X11):"
        echo "$selected_names_oneline"
    elif command -v xsel &> /dev/null; then
        echo -n "$selected_names_oneline" | xsel -ib
        echo "✅ Имена пакетов скопированы в буфер обмена (X11):"
        echo "$selected_names_oneline"
    else
        echo "📋 Имена пакетов (скопируйте вручную):"
        echo "$selected_names_oneline"
        echo "⚠ Установите wl-copy, xclip или xsel для автоматического копирования"
    fi
else
    echo "❌ Ничего не выбрано"
fi
