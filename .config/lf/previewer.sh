#!/bin/bash
draw() {
  kitten icat --stdin no --transfer-mode memory --place "${w}x${h}@${x}x${y}" "$1" </dev/null >/dev/tty
  exit 1
}

file="$1"
w="$2"
h="$3"
x="$4"
y="$5"

case "$(file -Lb --mime-type "$file")" in 
  image/*)
    draw "$file"
    ;;
  video/*)
     echo "File: $(basename "$file")"
    echo "Size: $(du -h "$file" | cut -f1)"
    echo "Type: $mime_type"
    ;;

  *)
    echo "File: $(basename "$file")"
    echo "Size: $(du -h "$file" | cut -f1)"
    echo "Type: $mime_type"
    ;;
esac

pistol "$file"
