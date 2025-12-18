#!/bin/bash
# ~/.config/hypr/scripts/preview.sh

FILE="$1"
WIDTH="$2"
HEIGHT="$3"

# Определяем тип файла
mime_type=$(file --mime-type -b "$FILE")

case "$mime_type" in
    image/*)
        # Для изображений используем chafa
        chafa --size=${WIDTH}x${HEIGHT} "$FILE"
        ;;
    video/*)
        # Для видео создаем превью с помощью ffmpegthumbnailer
        ffmpegthumbnailer -i "$FILE" -o /tmp/video_preview.jpg -s 0 -q 10
        chafa --size=${WIDTH}x${HEIGHT} /tmp/video_preview.jpg
        ;;
    *)
        # Для других файлов показываем информацию
        echo "File: $(basename "$FILE")"
        echo "Size: $(du -h "$FILE" | cut -f1)"
        echo "Type: $mime_type"
        ;;
esac
