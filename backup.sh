#! /bin/bash

<< 'Description'
This script automates log backup management. It compresses the log 
directory into a timestamped .zip archive and stores it in a 
dedicated backup folder. To prevent unbounded disk usage, it retains 
only the 5 most recent backups and automatically deletes older ones. 
The script is designed to run on a schedule via cron for hands-off, 
continuous log archival.
Description


src_dir=$1
backup_dir=$2
timestamp=$(date +%Y-%m-%d_%H-%M-%S)

function check_parameters_present {

if [ $# -le 1 ]; then
	echo "Arguments are not given"
	exit 1
else
	echo "Source directory : ${src_dir}" 
	echo "Backup Directory : ${backup_dir}"
fi

}

function create_backup {
	zip -r "${backup_dir}/backup-${timestamp}.zip" $src_dir
	if [ $? -eq 0 ];then
		echo "backup is created successfully"
	else
		echo "backup failed"
	fi
}

function delete_old_backups {

	backups=($(ls -t $backup_dir))
	# echo "Backups in order of older : ${backups[@]}"
	backups_to_delete=("${backups[@]:5}")
	
	if [ "${#backups_to_delete[@]}" -eq 0 ];then
		echo "Nothing to be deleted"
	else
		echo "backups file to delete : ${backups_to_delete[@]}"
		echo "started the deletion" 
		for file in "${backups_to_delete[@]}";do
			rm -f "${backup_dir}/${file}"
		done

		if [ $? -eq 0 ];then
			echo "Delted successfully"
		else
			echo "Not deleted"
		fi
	fi
}

check_parameters_present "$@"
create_backup
delete_old_backups
