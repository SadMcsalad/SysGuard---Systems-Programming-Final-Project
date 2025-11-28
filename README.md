How to Run the Script:
The monitoring script does not require command-line arguments.
To run it manually: ./sysguard.sh
If needed: chmod +x sysguard.sh
     ./sysguard.sh 
When used with cron, call it using an absolute path: /home/user/monitor/sysguard.sh 


Inputs and Configuration
The script uses a single configuration file:
thresholds.conf
Which contains adjustable settings:
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=85
SERVICES="cron sshd systemd-journald"
EMAIL="your@gmail.com"

The script also reads from the system log:
/var/log/syslog
And maintains a small internal file for anomaly detection:
anomaly_data/cpu_history.log
Both are created automatically if missing.
Outputs
The script generates:
1. SystemHealth.log
A timestamped report including:
CPU, memory, disk usage
uptime
top processes
service statuses
recent system log errors

2. Email Alert
A single email summarizing:
threshold violations
service failures
syslog errors
anomaly detections

3. CPU History File
Used internally for anomaly detection: anomaly_data/cpu_history.log

Example Usage
Manual Run: ./sysguard.sh
Cron (daily at 12 AM): 0 0 * * * /home/user/monitor/sysguard.sh
Testing Log Alerts: logger "TEST_ERROR simulation"
        ./sysguard.sh
Testing CPU Anomaly Detection: yes > /dev/null &
       sleep 5
                                                       killall yes
       ./sysguard.sh

Command-Line Arguments
The script intentionally uses a configuration-file approach instead of command-line flags.
All settings (thresholds, email, services) are defined in thresholds.conf, making the script easier to maintain and automate.
