#!/bin/bash
# ~/.local/bin/toggle-ime-mode.sh

FCITX_CONF="$HOME/.config/environment.d/10-fcitx.conf"
DISABLED="$FCITX_CONF.disabled"

if [ -f "$FCITX_CONF" ]; then
  # Выключаем fcitx режим
  mv "$FCITX_CONF" "$DISABLED"
  killall fcitx5 2>/dev/null
  notify-send "IME Mode" "Native (restart apps)"
else
  # Включаем fcitx режим
  mv "$DISABLED" "$FCITX_CONF"
  fcitx5 -d
  notify-send "IME Mode" "fcitx5 (restart apps)"
fi
