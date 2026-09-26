#!/bin/bash

<< task
Automate the process of creating a EC2 instance

Usage:
  ./create-ec2.sh <ami_id> <instance_type> <key_name> <subnet_id> <security_group_id> <instance_name>
task

ami_id="$1"
instance_type="$2"
key_name="$3"
subnet_id="$4"
security_group_ids="$5"
instance_name="$6"

function check_parameters {
	if [ $# -lt 6 ]; then
		echo "Usage: $0 <ami_id> <instance_type> <key_name> <subnet_id> <security_group_id> <instance_name>"
		exit 1
	fi
}

function install_aws_cli {

	if command -v aws >/dev/null 2>&1; then
		echo -e "aws-cli is already installed, so skipping the install of aws \n"
		return 0
	fi

	# unzip is needed to extract the installer, curl to download it
	for tool in curl unzip; do
		if ! command -v "${tool}" >/dev/null 2>&1; then
			echo -e "${tool} is not present, so we are installing it \n"
			sudo apt-get install -y "${tool}" || { echo "Failed to install ${tool}"; return 1; }
		else
			echo -e "${tool} is already installed so skipping its installation \n"
		fi
	done

	curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	if [ $? -ne 0 ]; then
		echo "Failed to download AWS CLI"
		return 1
	fi
	echo -e "AWS CLI is downloaded successfully \n"

	echo -e "Starting the unzipping of aws file \n"
	unzip -q -o awscliv2.zip || { echo "Failed to unzip awscliv2.zip"; return 1; }

	echo -e "Installing the aws-cli \n"
	if sudo ./aws/install; then
		echo -e "aws-cli is installed successfully \n version installed : $(aws --version) \n"
		rm -rf awscliv2.zip aws
	else
		echo "There is some issue while installing aws-cli"
		return 1
	fi
}

function wait_for_instance() {
	local instance_id="$1"
	local state
	echo "Waiting for instance $instance_id to be in running state..."

	while true; do
		state=$(aws ec2 describe-instances --instance-ids "$instance_id" \
			--query 'Reservations[0].Instances[0].State.Name' --output text)
		case "$state" in
			running)
				echo "Instance $instance_id is now running."
				return 0
				;;
			terminated|shutting-down|stopping|stopped)
				echo "Instance $instance_id entered unexpected state: $state"
				return 1
				;;
			*)
				echo "Instance is still not up (state: ${state:-unknown})..."
				;;
		esac
		sleep 5
	done
}

function create_instance() {
	echo -e "Start creating the ec2 instance ... \n"
	local instance_id
	instance_id=$(aws ec2 run-instances \
		--image-id "$ami_id" \
		--instance-type "$instance_type" \
		--key-name "$key_name" \
		--subnet-id "$subnet_id" \
		--security-group-ids "$security_group_ids" \
		--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]" \
		--query 'Instances[0].InstanceId' \
		--output text)

	if [ -z "${instance_id}" ] || [ "${instance_id}" == "None" ]; then
		echo "Instance is not created"
		return 1
	fi
	echo -e "Instance is created, your instance id is ${instance_id} \n"

	wait_for_instance "${instance_id}"
}

check_parameters "$@"
install_aws_cli || exit 1
create_instance || exit 1
