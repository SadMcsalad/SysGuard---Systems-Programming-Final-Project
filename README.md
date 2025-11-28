<h1>How to Run the Script</h1>

The monitoring script does not require command-line arguments.

To run it manually:

```bash
./sysguard.sh
```

If needed, make it executable:
```
chmod +x sysguard.sh
./sysguard.sh
```
When used with cron, call it using an absolute path:
```
/home/user/monitor/sysguard.sh
```

<h1>Inputs and Configuration</h1>

The script utilizes a single configuration file named thresholds.conf

This file contains adjustable settings:
```bash
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=85
SERVICES="cron sshd systemd-journald"
EMAIL="your@gmail.com"
```

The script also reads from the system log:
```
/var/log/syslog
```

It also maintains an internal file for anomaly detection:
```
anomaly_data/cpu_history.log
```
These files are automatically created if missing.

<h1>Outputs</h1>
1. SystemHealth.log
A timestamped report including: 

* CPU, memory, and disk usage
* System uptime
* Top resource-consuming processes
* Service statuses
* Recent system log errors

2. Email Alert

A single combined email summarizing:

* Threshold violations
* Service failures
* Syslog errors
* Anomaly detections

3. CPU History File

Used internally for anomaly detection:
```bash
anomaly_data/cpu_history.log
```
<h1>Example Usage</h1>
Manual Run 

``` bash
./sysguard.sh
```
Cron (daily at 12 AM)

``` bash
0 0 * * * /home/user/monitor/sysguard.sh
```
Testing Log Alerts

```bash
logger "TEST_ERROR simulation"
./sysguard.sh
```
Testing CPU Anomaly Detection

```bash
yes > /dev/null &
sleep 5
killall yes
./sysguard.sh
```

<h1>Command-Line Arguments</h1>

This monitoring script does not require any command-line arguments.
All configuration is handled via the external configuration file:

```bash
thresholds.conf
```
Using a configuration file provides:

* Centralized control of thresholds, email settings, and service lists

* Easier automation with cron

* No need to retype arguments each run

* Cleaner and more maintainable design

All settings are automatically loaded at runtime:

```bash
source "$(dirname "$0")/thresholds.conf"
```

