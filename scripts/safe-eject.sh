#!/bin/bash
#/extra/scripts/script source/safe_eject.sh

echo "Поиск USB-устройств..."

mapfile -t usb< <(lsblk -d -o NAME,SIZE,TYPE,TRAN,VENDOR,MODEL | grep -i usb | head -3)
for line in "${usb[@]}"; do
	usbn+=$(echo "$line" | awk '{print $1}')
done
if [[ ${#usbn[@]} -eq 0 ]]; then
	echo "USB-устройства не найдены"
	exit 1
fi
echo 
echo "Найдены следующие USB-устройства"
for i in "${!usbn[@]}"; do
	echo "$((i+1)): ${usb[$i]}"
done
echo 
read -p "Введите имя флешки или её порядковый номер: " input
input="${input:-1}"
case "$input" in
	[1-9]) 
		index=$((input-1))
		selected="${usbn[$index]}"
		;;
	*sd*)
		selected=""
    	input="${input#*dev/}"
		input=$(echo "$input" | xargs)
    
    	for device in "${usbn[@]}"; do
		    if [[ "$device" == "$input" ]]; then
            selected="$device"
            break
        fi
    done
		;;
	*)
		echo ""
		echo "Недопутимый синтаксис, выход"
		exit 1
		;;
esac
if [ -z "$selected" ]; then 
	echo ""
	echo "Нет сответствующего устройства"
	exit 1
fi
for select in "${usbn[@]}"; do
	if [[ "$selected" == "$select" ]]; then
		selected2="${usb[$i]}"
	fi
done 
echo "Вы уверены, что хотите извлечь следующее устройство?"
echo $selected2
read -p "[Y/n]:" allw
allw="${allw:-y}"
if [[ "${allw,,}" == "y" ]]; then
	mnt=$(lsblk -no MOUNTPOINTS /dev/$selected| grep -v '^$' | head -1)
	udiskie-umount -deL $mnt > /dev/null 2>&1
	notify-send "Устройство извлечено" > /dev/null 2>&1
else 
	echo "окак"
	exit 1
fi