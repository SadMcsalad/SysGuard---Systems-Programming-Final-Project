#!/bin/bash

#load our threshold values
source "$(dirname "$0")/thresholds.conf"

#create timestamp
timestamp=$(date "+%Y-%m-%d %H:%M:%S")

#where to store logs
logfile="SystemHealth.log"

#combined alert message
ALERT_MSG=""

#write header to log
echo "=============== System Health at $timestamp =============== " >> "$logfile"
echo "" >> "$logfile"

############RECORDING COMPUTER STATS############

#record uptime
echo "--- Uptime ---" >> "$logfile"
uptime >> "$logfile"
echo "" >> "$logfile"

#record memory usage
echo "--- Memory Usage ---" >> "$logfile"
free -h >> "$logfile"
echo "" >> "$logfile"

#record disk usage
echo "--- Disk Usage ---" >> "$logfile"
df -h >> "$logfile"
echo "" >> "$logfile"

#record cpu usage
echo "--- CPU Usage ---" >> "$logfile"
top -b -n1 | grep "Cpu(s)" >> "$logfile"
echo "" >> "$logfile"

#extract numeric CPU, MEM, DISK values for threshold checks
cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d'.' -f1)
mem=$(free | awk '/Mem/ {printf("%.0f", $3/$2 * 100)}')
disk=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')

#record top processes
echo "--- Top Processes ---" >> "$logfile"
ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6 >> "$logfile"
echo "" >> "$logfile"

############THRESHOLD CHECKING############

#cpu alert
if [ "$cpu" -ge "$CPU_THRESHOLD" ]; then
    ALERT_MSG+="CPU usage too high: $cpu per cent\n"
fi

#memory alert
if [ "$mem" -ge "$MEM_THRESHOLD" ]; then
    ALERT_MSG+="Memory usage too high: $mem per cent\n"
fi

#disk alert
if [ "$disk" -ge "$DISK_THRESHOLD" ]; then
    ALERT_MSG+="Disk nearly full: $disk per cent\n"
fi

############ANOMALY DETECTION (CPU ONLY)############

#make directory if missing
mkdir -p anomaly_data

#append current cpu sample
echo "$(date +%s),$cpu" >> anomaly_data/cpu_history.log

#keep last 20 samples
tail -n 20 anomaly_data/cpu_history.log > anomaly_data/tmp && mv anomaly_data/tmp anomaly_data/cpu_history.log

#compute mean + std deviation
read mean std < <(
    awk -F',' '
        { vals[++n] = $2 }
        END {
            if (n == 0) { print "0 0"; exit }
            for (i = 1; i <= n; i++) sum += vals[i]
            mean = sum / n
            for (i = 1; i <= n; i++) diff += (vals[i] - mean) * (vals[i] - mean)
            std = (n > 1) ? sqrt(diff / n) : 0
            printf "%.2f %.2f", mean, std
        }
    ' anomaly_data/cpu_history.log
)

#anomaly threshold (3 standard deviations)
anomaly_threshold=$(awk -v m="$mean" -v s="$std" 'BEGIN { print m + 3*s }')

if (( $(echo "$cpu > $anomaly_threshold" | bc -l) )); then
    ALERT_MSG+="CPU anomaly detected: now=$cpu (mean=$mean std=$std)\n"
fi

############SERVICE MONITORING############

echo "--- Service Status ---" >> "$logfile"
for svc in $SERVICES; do
    if pgrep -x "$svc" > /dev/null; then
        echo "$svc: running" >> "$logfile"
    else
        echo "$svc: NOT running" >> "$logfile"
        ALERT_MSG+="$svc is DOWN on $(hostname) at $timestamp\n"
    fi
done
echo "" >> "$logfile"

############LOG PARSING############

echo "--- Recent Application Log Errors ---" >> "$logfile"

#parse log using sudo
errors=$(sudo grep -Ei "error|failed|warn" /var/log/syslog | tail -n 5)

if [ -n "$errors" ]; then
    echo "$errors" >> "$logfile"
    ALERT_MSG+="Log errors detected:\n$errors\n"
else
    echo "No errors detected" >> "$logfile"
fi

echo "" >> "$logfile"
echo "===============================================================" >> "$logfile"
echo "" >> "$logfile"

############SEND ONE COMBINED EMAIL############

if [ -n "$ALERT_MSG" ]; then
    echo -e "$ALERT_MSG" | mail -s "System Alert on $(hostname)" "$EMAIL"
fi



