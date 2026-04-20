#!/bin/bash

# Unicode block characters for graph (8 levels)
BLOCKS=('▁' '▂' '▃' '▄' '▅' '▆' '▇' '█')

# History file to store past CPU values
HISTORY_FILE='/tmp/waybar_cpu_history.txt'
HISTORY_LENGTH=5  # Number of bars in the graph

get_cpu_usage() {
    # Get current CPU usage from /proc/stat
    local line=$(head -n 1 /proc/stat)
    local fields=($line)
    
    # Calculate idle and total
    local idle=${fields[4]}
    local total=0
    
    # Sum all CPU time fields (skip first field which is "cpu")
    for ((i=1; i<${#fields[@]}; i++)); do
        total=$((total + fields[i]))
    done
    
    echo "$idle $total"
}

calculate_cpu_percent() {
    local idle1=$1
    local total1=$2
    local idle2=$3
    local total2=$4
    
    local idle_delta=$((idle2 - idle1))
    local total_delta=$((total2 - total1))
    
    if [ $total_delta -eq 0 ]; then
        echo "0"
        return
    fi
    
    # Calculate CPU usage percentage using awk for floating point
    local usage=$(awk "BEGIN {printf \"%.1f\", 100.0 * (1.0 - $idle_delta / $total_delta)}")
    
    # Clamp between 0 and 100
    if (( $(awk "BEGIN {print ($usage < 0)}") )); then
        echo "0"
    elif (( $(awk "BEGIN {print ($usage > 100)}") )); then
        echo "100"
    else
        echo "$usage"
    fi
}

load_history() {
    if [ -f "$HISTORY_FILE" ]; then
        local content=$(cat "$HISTORY_FILE")
        # Convert comma-separated values to array
        IFS=',' read -ra history <<< "$content"
        
        # Keep only last HISTORY_LENGTH entries
        local start=$((${#history[@]} - HISTORY_LENGTH))
        if [ $start -lt 0 ]; then
            start=0
        fi
        
        echo "${history[@]:$start}"
    else
        echo ""
    fi
}

save_history() {
    local history=("$@")
    echo "${history[*]}" | tr ' ' ',' > "$HISTORY_FILE"
}

value_to_block() {
    local value=$1
    
    # Convert value to index (0-7)
    local index=$(awk "BEGIN {printf \"%.0f\", $value / 100 * 7}")
    
    # Clamp index
    if [ $index -lt 0 ]; then
        index=0
    elif [ $index -gt 7 ]; then
        index=7
    fi
    
    echo "${BLOCKS[$index]}"
}

create_graph() {
    local history=("$@")
    local graph=""
    
    # If history is empty, create default graph
    if [ ${#history[@]} -eq 0 ]; then
        for ((i=0; i<HISTORY_LENGTH; i++)); do
            graph="${graph}▁"
        done
        echo "$graph"
        return
    fi
    
    # Pad history if needed
    while [ ${#history[@]} -lt $HISTORY_LENGTH ]; do
        history=(0 "${history[@]}")
    done
    
    # Create graph from history
    for value in "${history[@]}"; do
        graph="${graph}$(value_to_block "$value")"
    done
    
    echo "$graph"
}

# Get CPU measurements
read idle1 total1 <<< $(get_cpu_usage)
sleep 0.5
read idle2 total2 <<< $(get_cpu_usage)

# Calculate current CPU usage
cpu_percent=$(calculate_cpu_percent $idle1 $total1 $idle2 $total2)

# Load history and add current reading
history=($(load_history))
history+=("$cpu_percent")

# Keep only recent history
start=$((${#history[@]} - HISTORY_LENGTH))
if [ $start -lt 0 ]; then
    start=0
fi
history=("${history[@]:$start}")

# Save history
save_history "${history[@]}"

# Create graph
graph=$(create_graph "${history[@]}")

# Get integer percentage for output
cpu_percent_int=$(printf "%.0f" "$cpu_percent")

# Format output
text="${graph}"
tooltip="CPU Usage: ${cpu_percent}%\nGraph shows last ${HISTORY_LENGTH} readings"

# Output JSON
echo "{\"text\":\"${text}\",\"tooltip\":\"${tooltip}\",\"class\":\"cpu-graph\",\"percentage\":${cpu_percent_int}}"
