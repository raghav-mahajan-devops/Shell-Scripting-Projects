#!/usr/bin/env bash

set -euo pipefail

folder_path=$1
log_file=./log/log.txt
datetime=$(date +"%y-%m-%d-%H-%M-%S")
log() {
	echo "${datetime}: $*" | tee -a $log_file
}

usage() {
	echo " Use script like this $0 <Folder that need to be organized>"
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
		file_type=$(file "${folder_path}/$file" | awk '{print $2}')
		echo "fileType: $file_type"
		if [[ "$file_type" == 'JPEG' || "$file_type" == 'PNG' ]]; then
			if [[ ! -d ./images ]]; then
				log "Images folder not exisit, creating it"
				mkdir -p images
				if [[ $? -eq 0 ]]; then
					log "Folder created successfully"
				else
					log "Error while creating folder"
					exit 1
				fi
				log "Moving $file into images folder"
				cp ${folder_path}/$file ./images/
				if [[ $? -eq 0 ]]; then
					log "File $file is moved to images folder successfully"
				else
					log "Error occur while moving file $file into images folder"

				fi
			else
				log "Folder images exist, moving to next step"
				log "Moving $file into images folder"
				cp ${folder_path}/$file ./images/
				if [[ $? -eq 0 ]]; then
					log "File $file is moved to images folder successfully"
				else
					log "Error occur while moving file $file into images folder"
				fi
			fi
		elif [[ "$file_type" == 'HTML' || "$file_type" == 'CSS' ]]; then
			if [[ ! -d ./web ]]; then
				log "Folder web not exist, creating it"
				mkdir -p web
				if [[ $? -eq 0 ]]; then
					log "Folder created successfully"
				else
					log "Error while creating folder"
					exit 1
				fi
				log "Moving file into folder web"
				cp ${folder_path}/$file ./web
				if [[ $? -eq 0 ]]; then
					log "File $file is moved to web folder successfully"
				else
					log "Error occur while moving file $file into web folder"
				fi
			else
				log "Folder web exist moving to next step"
				log "Moving file into folder web"
				cp ${folder_path}/$file ./web
				if [[ $? -eq 0 ]]; then
					log "File $file is moved to web folder successfully"
				else
					log "Error occur while moving file $file into web folder"
				fi
			fi

		elif [[ "$file_type" == 'XLSX' || "$file_type" == 'DOCS' || "$file_type" == 'PDF' || "$file_type" == 'CSV' || "$file_type" == 'Microsoft' ]]; then
			if [[ ! -d ./documents ]]; then
				log "Folder documents not exist, creating it"
				mkdir -p documents
				if [[ $? -eq 0 ]]; then
					log "Folder created successfully"
				else
					log "Error while creating folder"
					exit 1
				fi
				log "Moving file into folder documents"
				cp ${folder_path}/$file ./documents
				if [[ $? -eq 0 ]]; then
					log "File $file is moved to documents folder successfully"
				else
					log "Error occur while moving file $file into documents folder"
				fi
			else
				log "Folder documents exist moving to next step"
				log "Moving file into folder documents"
				cp ${folder_path}/$file ./documents
				if [[ $? -eq 0 ]]; then
					log "File $file is moved to documents folder successfully"
				else
					log "Error occur while moving file $file into documents folder"
				fi
			fi
		else
			if [[ ! -d ./others ]]; then
				log "Folder others not exist, creating it"
				mkdir -p others
				if [[ $? -eq 0 ]]; then
					log "Folder created successfully"
				else
					log "Error while creating folder"
					exit 1
				fi
				log "Moving file into folder others"
				cp ${folder_path}/$file ./others
				if [[ $? -eq 0 ]]; then
					log "File $file is moved to others folder successfully"
				else
					log "Error occur while moving file $file into others folder"
				fi
			else
				log "Folder others exist moving to next step"
				log "Moving file into folder others"
				cp ${folder_path}/$file ./others
				if [[ $? -eq 0 ]]; then
					log "File $file is moved to others folder successfully"
				else
					log "Error occur while moving file $file into others folder"
				fi
			fi
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
