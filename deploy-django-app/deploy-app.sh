#!/bin/bash

<< "task"
Deploy a django app and
handle the code error
task

repo_url="https://github.com/LondheShubham153/django-notes-app.git"
repo_dir="django-notes-app"
image_name="notesapp"
container_name="notesapp"

# clone the code

function clone_repo {

	if [ ! -d "${repo_dir}" ]; then
		echo -e "******************************* start cloning the app ****************************** \n"
		if git clone "${repo_url}"; then
			echo -e "*********************** App is cloned successfully ************************* \n"
		else
			echo -e "*********************** App is not cloned, some failure occurred *********** \n"
			return 1
		fi
	else
		echo -e "******************************* App is already cloned ****************************** \n"
	fi
}

# function install the requirements

function install_requirements {
	echo -e "**************************************** updating the apt-get ******************************** \n"
	sudo apt-get update || return 1
	local package=(docker.io nginx docker-compose)

	for pkg in "${package[@]}"; do
		if dpkg -s "${pkg}" >/dev/null 2>&1; then
			echo -e "******************************** ${pkg} is already installed ************************* \n"
		else
			echo -e "******************************** installing the ${pkg} ******************************* \n"
			sudo apt-get install -y "${pkg}" || { echo "Failed to install ${pkg}"; return 1; }
		fi
	done
}

function restart_services {
	echo -e "*************************************** Enabling and starting services *********************** \n"
	sudo systemctl enable --now docker || return 1
	sudo systemctl enable --now nginx || return 1

	echo -e "*************************************** Changing the ownership for docker.sock *************** \n"
	sudo chown "$USER" /var/run/docker.sock || return 1
}

function deploy_app {
	cd "${repo_dir}" || { echo "Cannot enter ${repo_dir}"; return 1; }
	echo -e "****************************************** Listing the folders in the repo ********************** \n"
	ls -l
	echo -e "*************************************** building and deploying the app *********************** \n"

	docker build -t "${image_name}" . || { echo "docker build failed"; return 1; }

	# remove a previous container so re-running the script does not hit a port conflict
	if docker ps -a --format '{{.Names}}' | grep -qx "${container_name}"; then
		echo "Removing the existing ${container_name} container"
		docker rm -f "${container_name}" || return 1
	fi

	docker run -d --name "${container_name}" -p 8000:8000 "${image_name}:latest" || { echo "docker run failed"; return 1; }
	echo -e "*************************************** App build is successfully **************************** \n"
}

function run_script {
	clone_repo || exit 1
	install_requirements || exit 1
	restart_services || exit 1
	deploy_app || exit 1
}

run_script
