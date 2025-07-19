#!/bin/bash

refresh_rate=3
log_file="health_anomalies.log"
show_cpu=true
show_mem=true
show_disk=true
show_net=true

# Clear log file on each run
> "$log_file"

# Color constants
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

draw_bar() {
    usage=$1
    label=$2
    bar=""
    level=$GREEN

    if (( usage > 80 )); then
        level=$RED
    elif (( usage > 60 )); then
        level=$YELLOW
    fi

    for ((i=0; i<usage/2; i++)); do
        bar+="#"
    done

    printf "%-10s [${level}%-50s${NC}] %3d%%\n" "$label" "$bar" "$usage"
}

get_cpu_usage() {
    local idle1 idle2 total1 total2
    read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    idle1=$idle
    total1=$((user + nice + system + idle + iowait + irq + softirq + steal))

    sleep 1
    read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    idle2=$idle
    total2=$((user + nice + system + idle + iowait + irq + softirq + steal))

    cpu_usage=$((100 * ( (total2 - total1) - (idle2 - idle1) ) / (total2 - total1) ))
    echo $cpu_usage
}

get_mem_usage() {
    read total used <<< $(free | awk '/Mem/ {print $2, $3}')
    echo $(( 100 * used / total ))
}

get_disk_usage() {
    df / --output=pcent | tail -1 | tr -dc '0-9'
}

get_net_usage() {
    read rx1 tx1 < <(cat /proc/net/dev | awk '/eth0|enp|wlan/ {rx+=$2; tx+=$10} END {print rx, tx}')
    sleep 1
    read rx2 tx2 < <(cat /proc/net/dev | awk '/eth0|enp|wlan/ {rx+=$2; tx+=$10} END {print rx, tx}')
    rx_kbps=$(( (rx2 - rx1) / 1024 ))
    tx_kbps=$(( (tx2 - tx1) / 1024 ))
    echo "$rx_kbps $tx_kbps"
}

log_anomaly() {
    echo "[$(date)] $1" >> "$log_file"
}

trap "stty sane; clear; exit" SIGINT SIGTERM

main_loop() {
    while true; do
        clear
        echo -e "📊 ${GREEN}System Health Dashboard${NC} - Refresh: ${refresh_rate}s  |  Press [r]efresh rate  [f]ilter  [q]uit"
        echo "------------------------------------------"

        [[ "$show_cpu" = true ]] && {
            cpu=$(get_cpu_usage)
            draw_bar $cpu "CPU"
            ((cpu > 80)) && log_anomaly "High CPU usage: $cpu%"
        }

        [[ "$show_mem" = true ]] && {
            mem=$(get_mem_usage)
            draw_bar $mem "Memory"
            ((mem > 75)) && log_anomaly "High Memory usage: $mem%"
        }

        [[ "$show_disk" = true ]] && {
            disk=$(get_disk_usage)
            draw_bar $disk "Disk"
            ((disk > 85)) && log_anomaly "Disk almost full: $disk%"
        }

        [[ "$show_net" = true ]] && {
            read rx tx <<< $(get_net_usage)
            printf "%-10s RX: %s KB/s  TX: %s KB/s\n" "Network" "$rx" "$tx"
        }

        read -t "$refresh_rate" -n 1 key
        case "$key" in
            q) break ;;
            r)
                echo -ne "\nEnter new refresh rate (seconds): "
                read new_rate
                [[ "$new_rate" =~ ^[0-9]+$ ]] && refresh_rate=$new_rate
                ;;
            f)
                echo -ne "\nToggle sections (y/n):\n"
                read -p " Show CPU? " a; [[ "$a" == "n" ]] && show_cpu=false || show_cpu=true
                read -p " Show Memory? " a; [[ "$a" == "n" ]] && show_mem=false || show_mem=true
                read -p " Show Disk? " a; [[ "$a" == "n" ]] && show_disk=false || show_disk=true
                read -p " Show Network? " a; [[ "$a" == "n" ]] && show_net=false || show_net=true
                ;;
        esac
    done
}

main_loop
