#!/bin/bash

<< 'Description'
This script automates log backup management. It compresses the log
directory into a timestamped .zip archive and stores it in a
dedicated backup folder. To prevent unbounded disk usage, it retains
only the 5 most recent backups and automatically deletes older ones.
The script is designed to run on a schedule via cron for hands-off,
continuous log archival.

Usage:
  ./backup.sh <source_dir> <backup_dir>
Description

src_dir="$1"
backup_dir="$2"
timestamp=$(date +%Y-%m-%d_%H-%M-%S)
keep=5

function check_parameters_present {

	if [ $# -lt 2 ]; then
		echo "Arguments are not given"
		echo "Usage: $0 <source_dir> <backup_dir>"
		exit 1
	fi

	if [ ! -d "${src_dir}" ]; then
		echo "Source directory '${src_dir}' does not exist"
		exit 1
	fi

	if ! command -v zip >/dev/null 2>&1; then
		echo "zip is not installed. Install it with: sudo apt-get install -y zip"
		exit 1
	fi

	mkdir -p "${backup_dir}" || { echo "Cannot create backup directory '${backup_dir}'"; exit 1; }

	echo "Source directory : ${src_dir}"
	echo "Backup Directory : ${backup_dir}"
}

function create_backup {
	if zip -r "${backup_dir}/backup-${timestamp}.zip" "${src_dir}"; then
		echo "backup is created successfully"
	else
		echo "backup failed"
		exit 1
	fi
}

function delete_old_backups {

	# only consider our own backup archives, newest first
	mapfile -t backups < <(ls -t "${backup_dir}"/backup-*.zip 2>/dev/null)
	backups_to_delete=("${backups[@]:${keep}}")

	if [ "${#backups_to_delete[@]}" -eq 0 ]; then
		echo "Nothing to be deleted"
		return 0
	fi

	echo "backup files to delete : ${backups_to_delete[*]}"
	echo "started the deletion"
	local failed=0
	for file in "${backups_to_delete[@]}"; do
		rm -f -- "${file}" || failed=1
	done

	if [ "${failed}" -eq 0 ]; then
		echo "Deleted successfully"
	else
		echo "Some old backups could not be deleted"
		return 1
	fi
}

check_parameters_present "$@"
create_backup
delete_old_backups
