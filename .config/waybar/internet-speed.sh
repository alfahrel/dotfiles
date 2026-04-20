#!/bin/bash

get_bytes() {
    local interface="$1"
    local rx_bytes=0
    local tx_bytes=0
    
    while IFS= read -r line; do
        if echo "$line" | grep -q "$interface"; then
            # Parse the line - rx_bytes is field 2, tx_bytes is field 10
            rx_bytes=$(echo "$line" | awk '{print $2}')
            tx_bytes=$(echo "$line" | awk '{print $10}')
            break
        fi
    done < /proc/net/dev
    
    echo "$rx_bytes $tx_bytes"
}

format_speed() {
    local bytes_per_sec="$1"
    local mb_per_sec=$(awk "BEGIN {printf \"%.2f\", $bytes_per_sec / (1024 * 1024)}")
    echo "${mb_per_sec} "
}

find_active_interface() {
    local interface=""
    
    while IFS= read -r line; do
        # Skip header line
        if echo "$line" | grep -q "Iface"; then
            continue
        fi
        
        # Parse route table: field 2 is destination, field 8 is mask
        local dest=$(echo "$line" | awk '{print $2}')
        local mask=$(echo "$line" | awk '{print $8}')
        
        # Default route has destination and mask both as 00000000
        if [ "$dest" = "00000000" ] && [ "$mask" = "00000000" ]; then
            interface=$(echo "$line" | awk '{print $1}')
            break
        fi
    done < /proc/net/route
    
    if [ -z "$interface" ]; then
        echo "eth0"
    else
        echo "$interface"
    fi
}

# Find active interface
interface=$(find_active_interface)

# Get initial bytes
read rx1 tx1 <<< $(get_bytes "$interface")

# Wait 1 second
sleep 1

# Get bytes after 1 second
read rx2 tx2 <<< $(get_bytes "$interface")

# Calculate speeds
download_speed=$((rx2 - rx1))
upload_speed=$((tx2 - tx1))
total_speed=$((download_speed + upload_speed))

# Format speeds
total_formatted=$(format_speed $total_speed)
download_formatted=$(format_speed $download_speed)
upload_formatted=$(format_speed $upload_speed)

# Format output for Waybar
text=" ${total_formatted}"
tooltip="Interface: ${interface}\nTotal: ${total_formatted}\nDownload: ${download_formatted}\nUpload: ${upload_formatted}"

# Output JSON
echo "{\"text\":\"${text}\",\"tooltip\":\"${tooltip}\",\"class\":\"network-speed\"}"
