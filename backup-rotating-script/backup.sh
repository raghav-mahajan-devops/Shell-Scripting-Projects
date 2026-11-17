#!/usr/bin/env bash

set -euo pipefail

loc_of_data=$1
loc_of_backup=$2
loc_of_logfile=./log/log.txt
datetime=$(date +"%y-%m-%d-%H-%M-%S")
backup_to_keep=4
log() {
	echo " $datetime $* " | tee -a "$loc_of_logfile"
}

script_usage() {
	echo " Use script like this $0 <Data location to be backup> <Backup location> "
}

checking_folder_exist() {
	if [[ ! -d "$1" ]]; then
		log " $1 Folder dont exist"
		exit 1
	fi
}
Creting_backup() {
	log "checking tar is installed ..."
	tar_exist=$(command -v tar)
	if [[ -n "$tar_exist" ]]; then
		log "Tar is already installed"
		tar -czvf "$loc_of_backup"/backup_$datetime.tar.gz "$loc_of_data"
	else
		log "Tar is not present installing ..."
		sudo apt update
		sudo apt install tar -y
		tar_exist=$(command -v tar)
		if [[ -n tar_exist ]]; then
			log "Tar is installed successfull"
		else
			log "Tar installtion is failed "
			exit 1
		fi
	fi

}

deleting_old_backups() {
	# only list files created by this script, so nothing else in the backup folder is ever deleted
	mapfile -t backups < <(cd "$loc_of_backup" && ls -t -- backup_*.tar.gz 2>/dev/null)
	echo "${#backups[@]}"
	old_backups=("${backups[@]:${backup_to_keep}}")
	echo "${#old_backups[@]}"
	if [[ "${#old_backups[@]}" -eq 0 ]]; then
		log "Nothing to be deleted"
	else
		deletion_failed=0
		log "Deleting the old backups"
		for file in "${old_backups[@]}"; do
			log "file to be removed $file"
			rm -f -- "$loc_of_backup"/"$file" || deletion_failed=1;
		done
		if [[ $deletion_failed -eq 0 ]]; then
			log "old backup files are deleted successfully"
		else
			log "Some files are not able to deleted"
			exit 1
		fi
	fi

}

log "checking if arguments are given"
if [[ $# -ne 2 ]]; then
	script_usage
fi
log "Arguments are given"

log "Checking data folder exist"
checking_folder_exist "$loc_of_data"
log "Data folder exist"

log "Checking backup folder exist"
checking_folder_exist "$loc_of_backup"
log "backup folder exist"

log "All requirements are fullfiled , ready to start backup"

Creting_backup

if [[ -e "$loc_of_backup" ]]; then
	log "Backup is successfull"
fi

log "Deleting the old backups"

deleting_old_backups
