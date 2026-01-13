#!/bin/bash

STATE_FILE="$HOME/.config/waybar/.network-display-state"
DISPLAY_STATE="icon"

# Читаем состояние отображения
[ -f "$STATE_FILE" ] && DISPLAY_STATE=$(cat "$STATE_FILE")

# Получаем IP адрес
get_ip() {
    # Для ethernet
    IP=$(ip -4 addr show $(ip route | grep default | awk '{print $5}') 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1)
    
    # Если ethernet нет, проверяем wifi
    if [ -z "$IP" ]; then
        IP=$(ip -4 addr show wlan0 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1)
    fi
    
    echo ${IP:-"No IP"}
}

# Получаем тип соединения
get_connection_type() {
    if ip link show | grep -q "state UP" | grep -v "lo:"; then
        if ip link show | grep -q "enp"; then
            echo "ethernet"
        elif ip link show | grep -q "wlan"; then
            echo "wifi"
        else
            echo "connected"
        fi
    else
        echo "disconnected"
    fi
}

CONNECTION_TYPE=$(get_connection_type)
IP_ADDR=$(get_ip)

# Выводим в формате JSON для Waybar
if [ "$DISPLAY_STATE" = "text" ]; then
    echo "{\"text\": \"$IP_ADDR\", \"class\": \"expanded\", \"alt\": \"$CONNECTION_TYPE\"}"
else
    case $CONNECTION_TYPE in
        ethernet)
            echo "{\"text\": \"󰈀\", \"class\": \"collapsed\", \"alt\": \"$IP_ADDR\"}"
            ;;
        wifi)
            echo "{\"text\": \"\", \"class\": \"collapsed\", \"alt\": \"$IP_ADDR\"}"
            ;;
        disconnected)
            echo "{\"text\": \"⚠\", \"class\": \"disconnected\", \"alt\": \"Disconnected\"}"
            ;;
        *)
            echo "{\"text\": \"?\", \"class\": \"collapsed\", \"alt\": \"$IP_ADDR\"}"
            ;;
    esac
fi
