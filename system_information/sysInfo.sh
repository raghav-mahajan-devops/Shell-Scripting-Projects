#!/usr/bin/env bash

set -euo pipefail

datetime=$(date +"%y-%m-%d %H:%M:%S")
log_location=./log/log.txt

log(){
	echo "${datetime}:$*" | tee -a "${log_location}"
}

show_system_details(){
echo "=================================================="
echo "     SYSTEM INFORMATION REPORT                    "
echo "     $datetime                                    "
echo -e "==================================================\n"
hostname=$(hostname)
os=$(. /etc/os-release && echo "$PRETTY_NAME")
kernel=$(uname -r)
uptime=$(uptime -p)
printf "%-10s : %s\n" "Hostname" "$hostname"
printf "%-10s : %s\n" "OS"       "$os"
printf "%-10s : %s\n" "Kernel"   "$kernel"
printf "%-10s : %s\n" "Uptime"   "$uptime"

}

show_cpu_info(){
echo -e "\nCPU \n--------------------------------------------------"
printf "%-10s : %s\n" "cores" "$(nproc)"

}

show_memory(){
echo -e "\nMEMORY \n--------------------------------------------------"
totalMem=$(free -h | grep Mem | awk '{print $2}')
usedMem=$(free -h | grep Mem | awk '{print $3}')
availableMem=$(free -h | grep Mem | awk '{print $7}')
#usage=
swap_total=$(free -h | awk 'NR==3 {print $2}')
swap_used=$(free -h | awk 'NR==3 {print $3}')
printf "%-10s : %s\n" "Total" "$totalMem"
printf "%-10s : %s\n" "Used" "$usedMem"
printf "%-10s : %s\n" "Available" "$availableMem"
printf "%-10s : %s\n" "Usage" " Pending to implment"
printf "%-10s : %s\n" "Swap Total" "$swap_total"
printf "%-10s : %s\n" "Swap Used" "$swap_used"
}

show_system_details
show_cpu_info
show_memory
