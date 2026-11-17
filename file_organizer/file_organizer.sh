#!/usr/bin/env bash

set -euo pipefail

folder_path=$1
log_file=./log/log.txt
datetime=$(date +"%y-%m-%d-%H-%M-%S")
log() {
	echo "${datetime}: $*" | tee -a "$log_file"
}

usage() {
	echo " Use script like this $0 <Folder that need to be organized>"
}

# move_file <file name> <target folder>
# Creates the target folder if needed and moves the file into it.
# A file that already exists in the target folder is skipped, never overwritten.
move_file() {
	local file=$1
	local target=$2

	if [[ ! -d "./$target" ]]; then
		log "Folder $target not exist, creating it"
		if mkdir -p "./$target"; then
			log "Folder created successfully"
		else
			log "Error while creating folder"
			exit 1
		fi
	else
		log "Folder $target exist moving to next step"
	fi

	if [[ -e "./$target/$file" ]]; then
		log "File $file already exists in $target folder, skipping it"
		return 0
	fi

	log "Moving $file into $target folder"
	if mv -- "${folder_path}/$file" "./$target/"; then
		log "File $file is moved to $target folder successfully"
	else
		log "Error occur while moving file $file into $target folder"
	fi
}

organize_data() {
	log "Checking the total no of files in folder"
	mapfile -t files < <(ls "$folder_path")
	log "no of files ${#files[@]}"
	for f in "${files[@]}"; do
		log "File:$f"
	done
	for file in "${files[@]}"; do
		echo "FileName :$file"
		# -b prints only the type (no file name), so spaces in names do not shift the columns
		file_type=$(file -b "${folder_path}/$file" | awk '{print $1}')
		echo "fileType: $file_type"
		if [[ "$file_type" == 'JPEG' || "$file_type" == 'PNG' ]]; then
			move_file "$file" images
		elif [[ "$file_type" == 'HTML' ]] ||
			[[ "$file" == *.css && ("$file_type" == 'ASCII' || "$file_type" == 'Unicode') ]]; then
			move_file "$file" web
		elif [[ "$file_type" == 'PDF' || "$file_type" == 'Microsoft' ]]; then
			move_file "$file" documents
		else
			move_file "$file" others
		fi
	done
}

if [[ $# -ne 1 ]]; then
	log "Arguments are not given "
	usage
	exit 1
else
	log "Arguments are given proceeding next..."
fi

if [[ ! -d "$folder_path" ]]; then
	log "No folder of $folder_path exist in current directory"
	exit 1
else
	log "$folder_path exist in current directory proceeding next..."
fi

organize_data
