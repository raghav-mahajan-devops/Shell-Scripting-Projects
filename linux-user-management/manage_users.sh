#!/bin/bash

<<COMMENT
Creates Linux users in bulk from a CSV file (header line, then "username,group" per line).
Creates the group if missing, adds the user unless they already exist, and sets a random password.
Usage: ./manage_users.sh <csv_file>   (needs sudo and openssl)
COMMENT

csv_file=$1

created=0
skipped=0

no_of_records=$(cat "$csv_file" | wc -l)

for ((i=2; i<=$no_of_records; i++))
do
    group=$(cat "$csv_file" | awk -F, -v line=$i 'NR==line {print $2}')
    username=$(cat "$csv_file" | awk -F, -v line=$i 'NR==line {print $1}')
    groupExists=$(getent group "$group")
    if [ -z "$groupExists" ];then
        sudo groupadd "$group"
        if [ $? -eq 0 ]; then
            echo -e "[INFO] Group ${group} created \n"
        else
            echo -e "[ERROR] Failed to create group ${group} \n"
        fi
    fi
    userExists=$(getent passwd "$username")
    if [ -z "$userExists" ]; then
        sudo useradd -m -g "$group" "$username"
        if [ $? -eq 0 ];then
            echo -e "[INFO] User ${username} created in group ${group}\n"
            random_password=$(openssl rand -base64 12)
            echo "${username}:${random_password}" | sudo chpasswd >> output.txt
            sudo passwd -e "$username" >> output.txt
            created=$((created + 1))
        else
            echo -e "[ERROR] Failed to create user ${username} in group ${group}\n"
        fi
    else
        echo -e "[SKIP] User ${username} already exists\n"
        skipped=$((skipped + 1))
    fi
done

echo -e "\n[INFO] User creation process completed."
echo -e "[INFO] Total users created: $created"
echo -e "[INFO] Total users skipped (already exist): $skipped"  