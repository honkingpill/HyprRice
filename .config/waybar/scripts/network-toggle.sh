#!/bin/bash

STATE_FILE="$HOME/.config/waybar/.network-display-state"

if [ -f "$STATE_FILE" ]; then
    CURRENT_STATE=$(cat "$STATE_FILE")
else
    CURRENT_STATE="icon"
fi


if [ "$CURRENT_STATE" = "icon" ]; then
    echo "text" > "$STATE_FILE"
else
    echo "icon" > "$STATE_FILE"
fi

pkill -SIGRTMIN+8 waybar
