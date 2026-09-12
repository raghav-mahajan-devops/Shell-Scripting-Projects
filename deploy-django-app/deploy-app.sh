#! /bin/bash


<< "task"
Deploy a django app and
handle the code error
task

# clone the code 

function clone_repo {
	
	cloned=$(find /home -type d -name "django-notes-app" 2>/dev/null)
	if [ ! -n "$cloned" ];then
		echo "start cloning the app ..."
		git clone https://github.com/LondheShubham153/django-notes-app.git
		if [ $? -eq 0 ];then
			echo "App is cloned successfully"
		else
			echo "App is not cloned sum failures occur"
		fi
	else
		echo "App is already cloned."
	fi
}

# function install the requirements 

function install_requirements {
	docker_install=$(which docker.io)
	nginx_install=$(which nginx)
	compose_install=$(which docker-compose)
	sudo apt-get update
	if [ -z "$docker_install" ];then
		echo "installing the docker ..."
		sudo apt-get install -y docker.io
	else
		echo "Docker is already installed"

	fi

	if [ -z "$nginx_install" ];then
                echo "installing the nginx ..."
                sudo apt-get install -y nginx
        else
                echo "Nginx is already installed"

        fi

	if [ -z "$compose_install" ];then
                echo "installing the docker composer ..."
                sudo apt-get install -y docker-compose
        else
                echo "Docker composer is already installed"

        fi

}

function run_script {
clone_repo
install_requirements
}

run_script
