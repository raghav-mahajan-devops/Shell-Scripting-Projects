#! /bin/bash

<<COMMENT
Usage: ./log_analyzer.sh <path_to_nginx_log>

It reads the log file passed as the first argument and prints a summary
report: total number of requests, the top 10 client IPs, the top 10
requested URLs, and the count of 4xx and 5xx error responses.
COMMENT

log_file=${1}

if [ -z "${log_file}" ];then
        echo "log file is not given, please pass the log file."
        exit 1
else
        echo "Log File : ${log_file}"
fi

echo -e "================================= Nginx Log Report ================================= \n"

echo -e "Total number of requests : $(cat ${log_file} | wc -l) \n"

echo -e "Top 10 IPs : \n$(cat ${log_file} | awk '{print $1}' | sort | uniq -c | sort -nr | awk 'NR<=10 {print $2}') \n"

echo -e "Top 10 URLs : \n$(cat ${log_file} | awk '{print $7}' | sort | uniq -c | sort -r | awk 'NR<=10{print $2}') \n"

echo -e "4xx Errors : $(cat ${log_file} | awk '$9 >= 400 && $9<500' | awk 'END {print NR}')\n"

echo -e "5xx Errors : $(cat ${log_file} | awk '$9 >= 500 && $9<600' | awk 'END {print NR}')"