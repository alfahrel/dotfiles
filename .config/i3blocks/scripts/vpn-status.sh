#!/bin/bash

PID_FILE="/var/run/openvpn-vpn.pid"

if [ -n "$BLOCK_BUTTON" ] && [ "$BLOCK_BUTTON" = "1" ]; then
    if pgrep -f "openvpn.*proton" > /dev/null 2>&1; then
        PID=$(pgrep -f "openvpn.*proton")
        sudo pkill -P $$ openvpn 2>/dev/null || sudo kill $PID 2>/dev/null
        
        sleep 2
        
        if pgrep -f "openvpn.*proton" > /dev/null 2>&1; then
            sudo pkill openvpn
        fi
    else
        /usr/local/bin/vpn-toggle
    fi
    exit 0
fi

if pgrep -f "openvpn.*proton" > /dev/null 2>&1; then
    PID=$(pgrep -f "openvpn.*proton")
    
    if [ -f "/proc/$PID/cmdline" ]; then
        CONFIG=$(tr '\0' ' ' < /proc/$PID/cmdline 2>/dev/null | grep -oE '[^ ]+\.ovpn' | head -1)
        
        if [ -n "$CONFIG" ]; then
            COUNTRY=$(basename "$CONFIG" | sed 's/-free.*//' | tr '[:upper:]' '[:lower:]')
        else
            COUNTRY="on"
        fi
    else
        COUNTRY="on"
    fi

    echo "<span color='#a6e3a1'> 󰒋 ${COUNTRY} </span>"
else
    echo "<span color='#f38ba8'> 󰒋 off </span>"
fi
