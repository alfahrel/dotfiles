#!/bin/bash
pactl set-sink-mute @DEFAULT_SINK@ toggle

if pactl get-sink-mute @DEFAULT_SINK@ | grep -q "yes"; then
    echo 1 | sudo tee /sys/class/leds/platform::mute/brightness > /dev/null
else
    echo 0 | sudo tee /sys/class/leds/platform::mute/brightness > /dev/null
fi
