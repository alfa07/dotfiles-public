#!/bin/bash
# OOM Guardian - Proactive memory management for macOS
# Monitors memory pressure and kills processes before kernel panic

LOG_FILE="$HOME/Library/Logs/oom-guardian.log"
SWAP_THRESHOLD=10  # Kill if more than 10GB swap
MEM_THRESHOLD=90   # Kill if memory usage above 90%

# Whitelist of processes to never kill (space-separated)
WHITELIST="WindowServer loginwindow SystemUIServer"

# ANSI color codes
if [ -t 1 ]; then
    # Terminal output - use colors
    C_GREEN='\033[0;32m'
    C_YELLOW='\033[1;33m'
    C_RED='\033[0;31m'
    C_RESET='\033[0m'
else
    # File/pipe output - no colors
    C_GREEN=''
    C_YELLOW=''
    C_RED=''
    C_RESET=''
fi

log_msg() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a "$LOG_FILE"
}

# Draw a progress bar
draw_bar() {
    local value=$1
    local max=$2
    local width=10
    local filled=$(echo "scale=0; $value * $width / $max" | bc 2>/dev/null || echo 0)
    filled=${filled%.*}  # Remove decimals
    [ $filled -gt $width ] && filled=$width
    [ $filled -lt 0 ] && filled=0

    local empty=$((width - filled))
    printf "|"
    printf '%*s' "$filled" '' | tr ' ' '*'
    printf '%*s' "$empty" '' | tr ' ' '-'
    printf "|"
}

# Get color based on percentage
get_color() {
    local percent=$1
    if (( $(echo "$percent < 70" | bc -l 2>/dev/null || echo 0) )); then
        echo -n "$C_GREEN"
    elif (( $(echo "$percent < 85" | bc -l 2>/dev/null || echo 0) )); then
        echo -n "$C_YELLOW"
    else
        echo -n "$C_RED"
    fi
}

# Shorten process name intelligently
shorten_name() {
    local name="$1"
    local max_len=15

    # Remove path prefixes
    name="${name##*/}"

    # Common substitutions
    name="${name//Google Chrome Helper/ChromeH}"
    name="${name//Google Chrome/Chrome}"
    name="${name//Firefox/FF}"
    name="${name//Safari/Sfr}"
    name="${name//com.apple./}"
    name="${name//python3/py3}"
    name="${name//node/nd}"
    name="${name//Docker/Dkr}"

    # Truncate if still too long
    if [ ${#name} -gt $max_len ]; then
        echo "${name:0:12}..."
    else
        echo "$name"
    fi
}

# Convert memory percentage to GiB
percent_to_gib() {
    local percent=$1
    local total_ram_gb=$(sysctl hw.memsize 2>/dev/null | awk '{print $2/1024/1024/1024}')
    total_ram_gb=${total_ram_gb:-16}  # Default to 16GB if can't detect

    echo "scale=1; $percent * $total_ram_gb / 100" | bc 2>/dev/null || echo "0.0"
}

is_whitelisted() {
    local process_name=$1
    for protected in $WHITELIST; do
        if [[ "$process_name" == *"$protected"* ]]; then
            return 0
        fi
    done
    return 1
}

# Log startup
log_msg "OOM Guardian started (PID: $$)"
log_msg "Thresholds: Mem=${MEM_THRESHOLD}%, Swap=${SWAP_THRESHOLD}GB | Whitelist: $WHITELIST"

while true; do
    # Get swap usage
    SWAP_INFO=$(sysctl vm.swapusage 2>/dev/null)
    SWAP_USED=$(echo "$SWAP_INFO" | grep -o "used = [0-9.]*G" | grep -o "[0-9.]*" | head -1)
    SWAP_USED=${SWAP_USED:-0}
    SWAP_USED_INT=${SWAP_USED%.*}

    # Get total RAM
    TOTAL_RAM_GB=$(sysctl hw.memsize 2>/dev/null | awk '{print $2/1024/1024/1024}')
    TOTAL_RAM_GB=${TOTAL_RAM_GB:-16}
    TOTAL_RAM_INT=${TOTAL_RAM_GB%.*}

    # Get total memory usage percentage
    MEM_PERCENT=$(ps aux | awk '{sum+=$4} END {printf "%.0f", sum}')
    MEM_PERCENT=${MEM_PERCENT:-0}

    # Calculate memory in GiB
    MEM_USED_GIB=$(echo "scale=0; $MEM_PERCENT * $TOTAL_RAM_GB / 100" | bc 2>/dev/null || echo 0)

    # Get top 3 processes
    TOP_PROCS=$(ps aux | grep -v kernel_task | awk 'NR>1 {print $4,$11}' | sort -rn | head -3)

    # Build top 3 processes string
    TOP3_STR=""
    i=1
    while IFS= read -r line; do
        mem_pct=$(echo "$line" | awk '{print $1}')
        proc_name=$(echo "$line" | awk '{$1=""; print $0}' | xargs)
        short_name=$(shorten_name "$proc_name")
        mem_gib=$(percent_to_gib "$mem_pct")
        TOP3_STR="${TOP3_STR}${short_name}[${mem_gib}G]"
        [ $i -lt 3 ] && TOP3_STR="${TOP3_STR}, "
        ((i++))
    done <<< "$TOP_PROCS"

    # Determine color
    COLOR=$(get_color "$MEM_PERCENT")

    # Build the log line
    MEM_BAR=$(draw_bar "$MEM_PERCENT" 100)
    SWAP_BAR=$(draw_bar "$SWAP_USED_INT" "$SWAP_THRESHOLD")

    LOG_LINE="${COLOR}Mem: ${MEM_BAR} ${MEM_USED_GIB}/${TOTAL_RAM_INT}G  Swap: ${SWAP_BAR} ${SWAP_USED_INT}/${SWAP_THRESHOLD}G${C_RESET}  Top3: ${TOP3_STR}"

    # Log it
    log_msg "$LOG_LINE"

    # Check if we're over threshold
    if (( $(echo "$MEM_PERCENT > $MEM_THRESHOLD" | bc -l 2>/dev/null || echo 0) )) || [ "$SWAP_USED_INT" -ge "$SWAP_THRESHOLD" ]; then
        log_msg "${C_RED}⚠ KILLING PROCESS${C_RESET}"

        # Get top 5 memory hogs (excluding kernel_task)
        ps aux | grep -v kernel_task | awk 'NR>1 {print $2,$4,$11}' | sort -k2 -rn | head -5 | while read pid mem name; do
            # Skip if whitelisted
            if ! is_whitelisted "$name"; then
                # Only kill if using >10% RAM
                if (( $(echo "$mem > 10.0" | bc -l 2>/dev/null || echo 0) )); then
                    mem_gib=$(percent_to_gib "$mem")
                    short_name=$(shorten_name "$name")
                    log_msg "${C_RED}→ Killing ${short_name} (PID:${pid}, Mem:${mem_gib}G)${C_RESET}"

                    # Try graceful termination first
                    kill -TERM $pid 2>/dev/null
                    sleep 2

                    # Force kill if still running
                    if kill -0 $pid 2>/dev/null; then
                        log_msg "  → Force kill PID $pid"
                        kill -9 $pid 2>/dev/null
                    fi

                    # Kill one process at a time, then re-evaluate
                    break
                fi
            else
                log_msg "  → Skipped (whitelisted): $(shorten_name "$name")"
            fi
        done

        # After killing a process, wait a bit longer for memory to be freed
        sleep 10
    fi

    # Check every 20 seconds
    sleep 20
done
