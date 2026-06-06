#!/bin/bash

LOG_FILE="server_health.log"
THRESHOLD_CPU=80
THRESHOLD_MEM=80
THRESHOLD_DISK=80
THRESHOLD_PROCESS=200

log_alert() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ALERT: $msg" | tee -a "$LOG_FILE"
}

log_info() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $msg" | tee -a "$LOG_FILE"
}

check_cpu() {
    echo "Checking CPU usage..."
    # Use vmstat for reliable idle percentage
    local idle=$(vmstat 1 2 | tail -1 | awk '{print $15}')
    # Fallback if idle is empty
    if [[ -z "$idle" ]]; then
        idle=0
    fi
    local cpu_usage=$((100 - idle))
    
    if [ "$cpu_usage" -gt "$THRESHOLD_CPU" ]; then
        log_alert "CPU usage is ${cpu_usage}% (Above ${THRESHOLD_CPU}% threshold)"
    else
        log_info "CPU usage is ${cpu_usage}% (Normal)"
    fi
}

check_memory() {
    echo "Checking memory usage..."
    local total=$(free | awk '/^Mem:/ {print $2}')
    local available=$(free | awk '/^Mem:/ {print $7}')
    local used=$((total - available))
    local mem_usage=$((used * 100 / total))
    
    if [ "$mem_usage" -gt "$THRESHOLD_MEM" ]; then
        log_alert "Memory usage is ${mem_usage}% (Above ${THRESHOLD_MEM}% threshold)"
    else
        log_info "Memory usage is ${mem_usage}% (Normal)"
    fi
}

check_disk() {
    echo "Checking disk usage..."
    df -P | tail -n +2 | while read line
    do
        USAGE=$(echo "$line" | awk '{print $5}' | tr -d '%')
        PARTITION=$(echo "$line" | awk '{print $6}')
        if [ "$USAGE" -gt "$THRESHOLD_DISK" ]; then
            log_alert "$PARTITION disk usage is ${USAGE}% (Above threshold)"
        else
            log_info "$PARTITION disk usage is ${USAGE}% (Normal)"
        fi
    done
}

check_processes() {
    echo "Checking running processes..."
    local proc_count=$(ps aux --no-headers | wc -l)
    
    if [ "$proc_count" -gt "$THRESHOLD_PROCESS" ]; then
        log_alert "Number of running processes is ${proc_count} (Above ${THRESHOLD_PROCESS} threshold)"
    else
        log_info "Running processes count is ${proc_count} (Normal)"
    fi
}

main() {
    echo "===== System Health Check Started =====" | tee -a "$LOG_FILE"
    check_cpu
    check_memory
    check_disk
    check_processes
    echo "===== System Health Check Completed =====" | tee -a "$LOG_FILE"
}

main
