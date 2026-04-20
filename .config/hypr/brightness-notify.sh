#!/bin/bash

# Change brightness
brightnessctl -e4 -n2 set "$1"

# Get current brightness percentage
brightness=$(brightnessctl g)
max_brightness=$(brightnessctl m)
percentage=$((brightness * 100 / max_brightness))

# Send notification
notify-send -t 1000 -h string:x-canonical-private-synchronous:brightness -h int:value:$percentage "Brightness" "$percentage%"
