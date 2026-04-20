#!/bin/bash
pactl set-source-mute @DEFAULT_SOURCE@ toggle

if pactl get-source-mute @DEFAULT_SOURCE@ | grep -q "yes"; then
    echo 1 | sudo tee /sys/class/leds/platform::micmute/brightness > /dev/null
else
    echo 0 | sudo tee /sys/class/leds/platform::micmute/brightness > /dev/null
fi
