#!/bin/bash

monitor_directory="store_csv"
interval=60

monitor_disk_usage() {
    mkdir -p "$monitor_directory"
    current_timestamp=$(date +%Y%m%d%H%M%S)
    logfile="${monitor_directory}/disk_monitor_${current_timestamp}.csv"
    
    echo "Timestamp,Filesystem,Size,Used,Avail,Use%,Mounted on,Inodes,IFree,IUse%,Mounted on" > "$logfile"

    while true; do
        timestamp=$(date +%Y-%m-%d\ %H:%M:%S)
        
        df_output=$(df -h | tail -n +2)
        
        inode_output=$(df -hi | tail -n +2)
        
        paste <(echo "$df_output") <(echo "$inode_output") | awk -v timestamp="$timestamp" '{print timestamp "," $0}' >> "$logfile"

        if [ "$(date +%Y%m%d)" != "$(date -r "$logfile" +%Y%m%d)" ]; then
            current_timestamp=$(date +%Y%m%d%H%M%S)
            logfile="${monitor_directory}/disk_monitor_${current_timestamp}.csv"
            echo "Timestamp,Filesystem,Size,Used,Avail,Use%,Mounted on,Inodes,IFree,IUse%,Mounted on" > "$logfile"
        fi
        
        sleep "$interval"
    done
}

start_monitor() {
    monitor_disk_usage &
    PID=$!
    echo $PID > /tmp/monitor_disk_usage.pid
    echo "Monitoring started with PID $PID"
}

stop_monitor() {
    if [ -f /tmp/monitor_disk_usage.pid ]; then
        PID=$(cat /tmp/monitor_disk_usage.pid)
        kill "$PID" && rm /tmp/monitor_disk_usage.pid
        echo "Monitoring stopped"
    else
        echo "Monitoring is not running"
    fi
}

status_monitor() {
    if [ -f /tmp/monitor_disk_usage.pid ]; then
        PID=$(cat /tmp/monitor_disk_usage.pid)
        if ps -p "$PID" > /dev/null; then
            echo "Monitoring is running with PID $PID"
            return
        fi
    fi
    echo "Monitoring is not running"
}

case "$1" in
    START)
        start_monitor
        ;;
    STOP)
        stop_monitor
        ;;
    STATUS)
        status_monitor
        ;;
    *)
        echo "Usage: $0 {START|STOP|STATUS}"
        exit 1
        ;;
esac