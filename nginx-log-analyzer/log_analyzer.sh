#!/usr/bin/env bash

set -euo pipefail

loc_of_log_file=$1
loc_of_script_log_file=./log/log.txt
datetime=$(date +"%y-%m-%d-%H-%M-%S")
log() {
	echo "$datetime : $*" >>"$loc_of_script_log_file"
}
usage() {

	echo "Seems required argumnets are not give Usage: $0 <location of your log file to analyze> "
}
show_no_of_request() {
	no_of_request=$(wc -l "$loc_of_log_file" | awk '{print $1}')
	echo -e "Total no of request: $no_of_request \n"
}
show_ip_addresses() {
	mapfile -t ips < <(awk '{print $1}' "$loc_of_log_file" | sort | uniq -c | sort -nr | head -n 5 | awk '{print $2}')
	for ip in "${ips[@]}"; do
		log "Ip : $ip"
		echo "Ip : $ip"
	done
}
show_popular_urls() {
	mapfile -t urls < <(awk '{print $7}' "$loc_of_log_file" | sort | uniq -c | sort -nr | awk 'NR<=5 {print $2}')
	for url in "${urls[@]}"; do
		log "Url: $url"
		echo "Url: $url"
	done
}
show_total_400_errors() {
	errors=$(awk '$9 >= 400 && $9 < 500' $loc_of_log_file | wc -l)
	log "Total 400 erros : $errors"
	echo -e "\nTotal 400 erros : $errors \n"
}
show_total_500_errors() {

	errors=$(awk '$9 >= 500 && $9 < 600' $loc_of_log_file | awk 'END{print NR} ')
	log "Total 500 erros : $errors"
	echo -e "Total 500 erros : $errors \n"
}

log "Checking the location of log file is given "
if [[ $# -ne 1 ]]; then
	usage
	exit 1
else
	log "log file location is given"

fi

log "checking file exist in the path"

if [[ -f $loc_of_log_file ]]; then
	log "File Exist"
else
	log "File not Exist stopping the script"
	exit 1
fi

log "All requirements meet starting the script"

show_no_of_request
echo -e "Most Frequent Ips \n"
show_ip_addresses
echo -e "\nMost Famous Urls \n"
show_popular_urls
show_total_400_errors
show_total_500_errors
