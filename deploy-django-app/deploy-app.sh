#! /bin/bash


<< "task"
Deploy a django app and
handle the code error
task

# clone the code 

function clone_repo {
	
	cloned=$(find /home -type d -name "django-notes-app" 2>/dev/null)
	if [ ! -n "$cloned" ];then
		echo -e "******************************* start cloning the app ****************************** \n"
		git clone https://github.com/LondheShubham153/django-notes-app.git
		if [ $? -eq 0 ];then
			echo -e "*********************** App is cloned successfully ************************* \n"
		else
			echo -e "*********************** App is not cloned sum failures occur *************** \n"
		fi
	else
		echo -e "******************************* App is already cloned ****************************** \n"
	fi
}

# function install the requirements 

function install_requirements {
	docker_install=$(which docker.io)
	nginx_install=$(which nginx)
	compose_install=$(which docker-compose)
	echo -e "**************************************** updating the apt-get ******************************** \n" 
	sudo apt-get update
	package=(docker.io nginx docker-compose)

	for pkg in "${package[@]}";do
		installed=$(dpkg -s ${pkg})
		if [ -z "$installed" ];then
			echo -e "******************************** installing the ${pkg} ******************************* \n"
			sudo apt-get install -y "$pkg"
		else
			echo -e "******************************** ${pkg} is already installed ************************* \n"
		fi
	done

}

function restart_services {
	echo -e "*************************************** Changing the ownership for docker.sock *************** \n"
	sudo chown $USER /var/run/docker.sock
	sudo systemctl enable docker
	sudo systemctl enable nginx
}

function deploy_app {
	cd django-notes-app
	echo "****************************************** Listing the folders in the repo ********************** \n"
	ls -l 
	echo -e "*************************************** building and deploying the app *********************** \n"
	docker build -t notesapp .
	docker run -d -p 8000:8000 notesapp:latest
	echo -e "*************************************** App build is successfully **************************** \n"
}	



function run_script {

clone_repo
install_requirements
restart_services
deploy_app
}

run_script
