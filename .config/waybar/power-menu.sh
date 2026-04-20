#!/bin/bash

# power-menu.sh with custom styling

entries=" Shutdown\n Reboot\n Suspend\n Lock\n Logout"

selected=$(echo -e "$entries" | wofi \
    --dmenu \
    --insensitive \
    --prompt "Power Menu" \
    --style ~/.config/wofi/power-menu.css \
    --width 300 \
    --height 300
    # --hide-search true
    # --cache-file /dev/null)
)
case $selected in
  " Shutdown")
    systemctl poweroff;;
  " Reboot")
    systemctl reboot;;
  " Suspend")
    systemctl suspend;;
  " Lock")
    hyprlock;;
  " Logout")
    hyprctl dispatch exit;;
  *)
    exit 0;;
esac
