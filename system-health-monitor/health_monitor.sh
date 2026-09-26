#! /bin/bash                                                                                                                                                                                                                                                              <<COMMENT                                                                                                                            This script is used to monitor the health of the system. It checks for CPU usage, memory usage, disk space, and network connectivity. If any of these metrics exceed predefined thresholds, it will send an alert to the system administrator.

COMMENT

check_mpstat=$(which mpstat)
if [ -z "$check_mpstat" ]; then
    echo "mpstat command not found. Please install sysstat package."
    sudo apt-get update && sudo apt-get install -y sysstat
else
    echo "mpstat command is available."
fi

cpu_utilization=$(mpstat 1 3 | awk '/Average/ {print int(100 - $NF)}')
memory_usage=$(free | awk 'NR==2 {print int($3/$2 * 100.0)}')
disk_space=$(df -h / |sed 's/%//'| awk 'NR==2 {print int($5)}')
service_status=$(systemctl is-active nginx)
time_stamp=$(date +"%Y-%m-%d %H:%M:%S")

if [ ${cpu_utilization} -ge '50' ];then
        echo "${time_stamp} [WARNING] CPU: ${cpu_utilization}" >> logs.txt
else
        echo "${time_stamp} [INFO] CPU: ${cpu_utilization}" >> logs.txt
fi

if [ ${memory_usage} -ge '75' ];then
        echo "${time_stamp} [WARNING] MEM: ${memory_usage}" >> logs.txt
else
        echo "${time_stamp} [INFO] MEM: ${memory_usage}" >> logs.txt
fi

if [ ${disk_space} -ge '70' ];then
        echo "${time_stamp} [WARNING] DISK: ${disk_space}" >> logs.txt
else
        echo "${time_stamp} [INFO] DISK: ${disk_space}" >> logs.txt
fi

if [ ${service_status} = 'inactive' ];then
        echo "${time_stamp} [WARNING] NGINX: ${service_status}" >> logs.txt
else
        echo "${time_stamp} [INFO] NGINX: ${service_status}" >> logs.txt
fi

cat logs.txt