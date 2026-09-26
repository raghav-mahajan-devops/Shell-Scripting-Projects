!# /bin/bash

<<COMMENT
This script is used to monitor the health of the system. It checks for CPU usage, memory usage, disk space, and network connectivity. If any of these metrics exceed predefined thresholds, it will send an alert to the system administrator.
COMMENT 

cpu_utilization=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
memory_usage=$(free | awk 'NR==2 {print int($3/$2 * 100.0)"%"}')
disk_space=$(df -h / | awk 'NR==2 {print $5}')
service_status=$(systemctl is-active nginx)
time_stamp=$(date +"%Y-%m-%d %H:%M:%S")
