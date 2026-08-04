#!/bin/bash

CONFIG_FILE="$HOME/.openvpn-config"

[ -n "$BLOCK_BUTTON" ] && [ "$BLOCK_BUTTON" = "1" ] && { /usr/local/bin/vpn-toggle; exit 0; }

if pgrep -f "openvpn.*proton" > /dev/null; then
    COUNTRY=$(basename "$(cat "$CONFIG_FILE" 2>/dev/null)" | sed 's/\.protonvpn\.udp\.ovpn//;s/-free//' | tr '[:upper:]' '[:lower:]')
    echo "<span color='#a6e3a1'> 󰕥 ${COUNTRY:-on} </span>"
else
    echo "<span color='#f38ba8'>  off </span>"
fi
