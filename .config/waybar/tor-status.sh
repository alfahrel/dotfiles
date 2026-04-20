#!/bin/bash

# State file to track previous status
STATE_FILE="$HOME/.cache/tor_status_state.json"

disable_proxy() {
    # Path to proxy config file
    local proxy_config="$HOME/.config/environment.d/proxy.conf"
    
    # Remove proxy config file
    [ -f "$proxy_config" ] && rm -f "$proxy_config"
    
    # Remove specific Tor iptables rules without flushing everything
    sudo iptables -t nat -D OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040 2>/dev/null
    sudo iptables -t nat -D OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353 2>/dev/null
    sudo iptables -t nat -D OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 5353 2>/dev/null
    
    # Clear Firefox proxy (if using Firefox)
    pkill -SIGUSR1 firefox 2>/dev/null
    
    # Clear Chromium/Chrome proxy via command line flags file
    local chrome_flags="$HOME/.config/chromium-flags.conf"
    if [ -f "$chrome_flags" ]; then
        grep -v -- '--proxy-server' "$chrome_flags" > "$chrome_flags.tmp" && mv "$chrome_flags.tmp" "$chrome_flags"
    fi
    
    # Clear Brave proxy
    local brave_flags="$HOME/.config/brave-flags.conf"
    if [ -f "$brave_flags" ]; then
        grep -v -- '--proxy-server' "$brave_flags" > "$brave_flags.tmp" && mv "$brave_flags.tmp" "$brave_flags"
    fi
    
    return 0
}

enable_proxy() {
    # Create environment.d directory if it doesn't exist
    local env_dir="$HOME/.config/environment.d"
    mkdir -p "$env_dir"
    
    # Write proxy configuration
    local proxy_config="$env_dir/proxy.conf"
    cat > "$proxy_config" << 'EOF'
# Tor SOCKS5 Proxy
http_proxy=socks5://127.0.0.1:9050
https_proxy=socks5://127.0.0.1:9050
HTTP_PROXY=socks5://127.0.0.1:9050
HTTPS_PROXY=socks5://127.0.0.1:9050
all_proxy=socks5://127.0.0.1:9050
ALL_PROXY=socks5://127.0.0.1:9050
EOF
    
    # Add Tor iptables rules
    sudo iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040 2>/dev/null
    sudo iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353 2>/dev/null
    sudo iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 5353 2>/dev/null
    
    return 0
}

toggle_tor_service() {
    # Check current status
    local is_active=$(systemctl is-active tor 2>/dev/null)
    
    if [ "$is_active" = "active" ]; then
        # Stop Tor and disable proxy
        sudo systemctl stop tor
        if disable_proxy; then
            notify-send -t 3000 -u normal 'Tor Disabled' 'Proxy settings removed' 2>/dev/null
        fi
    else
        # Start Tor and enable proxy
        sudo systemctl start tor
        if enable_proxy; then
            notify-send -t 3000 -u normal 'Tor Enabled' 'Proxy configured - restart apps to apply' 2>/dev/null
        fi
    fi
}

# Handle click events
if [ "$1" = "toggle" ]; then
    toggle_tor_service
    exit 0
fi

load_previous_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE" 2>/dev/null
    else
        echo '{"status":null,"bootstrap":0,"proxy_notified":false}'
    fi
}

save_state() {
    local status="$1"
    local bootstrap="$2"
    local proxy_notified="${3:-false}"
    
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "{\"status\":\"$status\",\"bootstrap\":$bootstrap,\"proxy_notified\":$proxy_notified}" > "$STATE_FILE"
}

check_tor_service() {
    local status=$(systemctl is-active tor 2>/dev/null)
    [ "$status" = "active" ] && echo "true" || echo "false"
}

check_tor_connection() {
    local response=$(curl -s --max-time 5 -A "Mozilla/5.0" "https://check.torproject.org/api/ip" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        if command -v jq &> /dev/null; then
            echo "$response" | jq -r '.IsTor // false'
        else
            echo "$response" | grep -o '"IsTor":[^,}]*' | cut -d':' -f2 | tr -d ' '
        fi
    else
        echo "false"
    fi
}

check_bootstrap() {
    local logs=$(journalctl -u tor -n 50 --no-pager 2>/dev/null)
    
    # Check for 100% bootstrap first
    if echo "$logs" | grep -q "Bootstrapped 100%"; then
        echo "100"
        return
    fi
    
    # Find the last bootstrap percentage
    local percent=$(echo "$logs" | grep "Bootstrapped" | tail -1 | grep -o "Bootstrapped [0-9]*%" | grep -o "[0-9]*")
    
    if [ -n "$percent" ]; then
        echo "$percent"
    else
        echo "0"
    fi
}

check_proxy_exists() {
    local proxy_config="$HOME/.config/environment.d/proxy.conf"
    [ -f "$proxy_config" ] && echo "true" || echo "false"
}

# Load previous state
prev_state=$(load_previous_state)

# Check Tor status
tor_service=$(check_tor_service)
if [ "$tor_service" = "true" ]; then
    bootstrap_percent=$(check_bootstrap)
else
    bootstrap_percent=0
fi

if [ "$bootstrap_percent" -eq 100 ]; then
    tor_connected=$(check_tor_connection)
else
    tor_connected="false"
fi

proxy_exists=$(check_proxy_exists)

# Manage proxy state
if [ "$tor_service" = "false" ] && [ "$proxy_exists" = "true" ]; then
    disable_proxy
    proxy_notified="true"
elif [ "$tor_service" = "true" ] && [ "$proxy_exists" = "false" ] && [ "$bootstrap_percent" -eq 100 ]; then
    enable_proxy
    proxy_notified="true"
else
    proxy_notified=$(echo "$prev_state" | grep -o '"proxy_notified":[^,}]*' | cut -d':' -f2 | tr -d ' ')
    [ -z "$proxy_notified" ] && proxy_notified="false"
fi

# Determine status
if [ "$tor_connected" = "true" ]; then
    icon=" "
    text="TOR"
    status_class="tor-active"
    tooltip="Tor network is active\nYour traffic is anonymized\nProxy enabled"
    current_status="connected"
elif [ "$tor_service" = "true" ] && [ "$bootstrap_percent" -gt 0 ]; then
    icon=" "
    text="${bootstrap_percent}%"
    status_class="tor-connecting"
    tooltip="Tor is connecting...\nBootstrap: ${bootstrap_percent}%"
    current_status="connecting"
elif [ "$tor_service" = "true" ]; then
    icon="󰔟"
    text="START"
    status_class="tor-starting"
    tooltip="Tor service is starting..."
    current_status="starting"
else
    icon="󱎛 "
    text="OFF"
    status_class="tor-off"
    tooltip="Tor is not running\nClick to start\nDirect connection"
    current_status="off"
fi

# Save current state
save_state "$current_status" "$bootstrap_percent" "$proxy_notified"

# Format output
echo "{\"text\":\"${icon}\",\"tooltip\":\"${tooltip}\",\"class\":\"${status_class}\",\"percentage\":${bootstrap_percent}}"
