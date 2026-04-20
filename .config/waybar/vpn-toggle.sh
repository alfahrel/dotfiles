#!/bin/bash
# =============================================================
# VPN Toggle Script for ProtonVPN with Random Server Selection
# =============================================================

CONFIGS=(
    "ca-free"
    "jp-free"
    "no-free"
    "mx-free-12.protonvpn.udp"
    "nl-free-135.protonvpn.udp"
    "pl-free-2.protonvpn.udp"
    "ro-free-28.protonvpn.udp"
    "sg-free-15.protonvpn.udp"
    "ch-free-4.protonvpn.udp"
)

STATE_FILE="/tmp/protonvpn-state"
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

# Check if any VPN is running
is_vpn_running() {
    systemctl is-active --quiet "openvpn-client@*"
}

# Stop all VPN connections
stop_vpn() {
    # Stop all openvpn services
    sudo systemctl stop "openvpn-client@*" 2>/dev/null
    
    # Also stop each config individually to be sure
    for config in "${CONFIGS[@]}"; do
        sudo systemctl stop "openvpn-client@${config}" 2>/dev/null
    done
    
    # Clean up state files
    rm -f "$STATE_FILE" "$CURRENT_FILE"
    
    # Give it a moment to fully stop
    sleep 0.5
    
    # Send notification
    notify-send -t 3000 -u normal "VPN Disconnected" "Your connection is no longer protected"
}

# Start random VPN
start_vpn() {
    # Stop any running VPN first
    sudo systemctl stop "openvpn-client@*" 2>/dev/null
    
    # Wait a moment for cleanup
    sleep 1
    
    # Pick a random config
    RANDOM_CONFIG="${CONFIGS[$RANDOM % ${#CONFIGS[@]}]}"
    
    # Get country code and name
    COUNTRY_CODE=$(echo "$RANDOM_CONFIG" | cut -d'-' -f1)
    COUNTRY_NAME=$(get_country_name "$COUNTRY_CODE")
    
    # Send connecting notification
    notify-send -t 3000 -u normal "VPN Connecting" "Connecting..."
    
    # Start the VPN
    sudo systemctl start "openvpn-client@${RANDOM_CONFIG}"
    
    # Wait for it to start
    sleep 3
    
    # Check if it actually connected
    if systemctl is-active --quiet "openvpn-client@${RANDOM_CONFIG}"; then
        # Save state
        echo "connected" > "$STATE_FILE"
        echo "$RANDOM_CONFIG" > "$CURRENT_FILE"
        
        # Send success notification
        notify-send -t 3000 -u normal "VPN Connected" "Connected to $COUNTRY_NAME"
        echo "VPN connected to $RANDOM_CONFIG"
    else
        # Send failure notification
        notify-send -t 3000 -u critical "VPN Failed" "Could not connect to $COUNTRY_NAME"
        echo "VPN failed to connect"
    fi
}

# Main toggle logic
if is_vpn_running; then
    stop_vpn
    echo "VPN disconnected"
else
    start_vpn
fi
