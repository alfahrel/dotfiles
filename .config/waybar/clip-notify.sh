#!/bin/bash

# Clipboard Monitor with Notifications for Wayland/Hyprland
# This script monitors the clipboard and shows a notification whenever content is copied
# Function to get clipboard content
get_clipboard() {
    wl-paste --no-newline 2>/dev/null
}

# Initialize with current clipboard content
previous_content=$(get_clipboard)

# Monitor loop
while true; do
    current_content=$(get_clipboard)
    
    # Check if clipboard has changed
    if [ "$current_content" != "$previous_content" ] && [ -n "$current_content" ]; then
        # Truncate long content for notification
        preview="${current_content:0:100}"
        if [ ${#current_content} -gt 100 ]; then
            preview="${preview}..."
        fi
        
        # Show notification
        notify-send "Content is copied!" "$preview" --urgency=low --expire-time=3000
        
        previous_content="$current_content"
    fi
    
    # Check every 0.5 seconds
    sleep 0.5
done
