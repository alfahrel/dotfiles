#!/bin/bash
# =============================================================
# VPN Status Script for Waybar
# =============================================================

CURRENT_FILE="/tmp/protonvpn-current"

# Country name mapping
get_country_name() {
    case "$1" in
        ca) echo "🇨🇦" ;;
        jp) echo "🇯🇵" ;;
        no) echo "🇳🇴" ;;
        mx) echo "🇲🇽" ;;
        nl) echo "🇳🇱" ;;
        pl) echo "🇵🇱" ;;
        ro) echo "🇷🇴" ;;
        sg) echo "🇸🇬" ;;
        ch) echo "🇨🇭" ;;
        *) echo "❓" ;;
    esac
}

# Check if VPN is running
if systemctl is-active --quiet "openvpn-client@*"; then
    if [ -f "$CURRENT_FILE" ]; then
        CONFIG=$(cat "$CURRENT_FILE")
        COUNTRY_CODE=$(echo "$CONFIG" | cut -d'-' -f1)
        COUNTRY_NAME=$(get_country_name "$COUNTRY_CODE")
        echo "{\"text\":\"$COUNTRY_NAME\",\"tooltip\":\"VPN Connected: $CONFIG\",\"class\":\"connected\"}"
    else
        echo "{\"text\":\" Connected\",\"tooltip\":\"VPN Connected\",\"class\":\"connected\"}"
    fi
else
    echo "{\"text\":\"󰷷\",\"tooltip\":\"VPN Disconnected - Click to connect\",\"class\":\"disconnected\"}"
fi
