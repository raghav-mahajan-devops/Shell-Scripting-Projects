#! /bin/bash

<< task
Automate the process of creating a EC2 instance
task


ami_id="$1"
instance_type="$2"
key_name="$3"
subnet_id="$4"
security_group_ids="$5"
instance_name="$6"


function install_aws_cli {

	is_aws_install=$(command -v aws)
	
	is_zip_install=$(command -v zip)
	
        if [ -z "${is_aws_install}" ];then
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                
		if [ $? -ne 0 ]; then
    			echo "Failed to download AWS CLI"
    			return 1
		else 
			echo -e "AWS CLI is downloaded successfully \n"
		fi

		if [ -z "${is_zip_install}" ];then
			echo -e "Zip is not present , so we are installing it \n"
			sudo apt-get install -y zip
		else
			echo -e "Zip is already installed so skipping its installation \n"
		fi
		
		echo -e "Starting the unzipping of aws file \n"
		
		unzip awscliv2.zip
		
		echo -e "installing the aws"
		
		./aws/install
		
		if [ $? -eq 0 ];then
			aws_version=$(aws --version)
			
			echo -e "aws-cli is installed successfully \n verson installed : ${aws_version} \n"
		else
			echo -e "There is some issue while installing aws-cli"
		fi
	
	else
		echo -e "aws-cli is already installed , so skipping the install of aws"
	fi	

}

function create_instance() {
	echo -e "Start creating the ec2 instance ... \n"
	instance_id=$(aws ec2 run-instances \
        --image-id "$ami_id" \
        --instance-type "$instance_type" \
        --key-name "$key_name" \
        --subnet-id "$subnet_id" \
        --security-group-ids "$security_group_ids" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]" \
        --query 'Instances[0].InstanceId' \
        --output text
    )
    if [ -n "${instance_id}" ];then
	    echo -e "Instace is created your instace id is "${instance_id}" \n"
    else
	    echo "Instace is not created"
    fi
	
    wait_for_instance "${instance_id}"

}

function wait_for_instance() {
    local instance_id="$1"
    echo "Waiting for instance $instance_id to be in running state..."

    while true; do
        state=$(aws ec2 describe-instances --instance-ids "$instance_id" --query 'Reservations[0].Instances[0].State.Name' --output text)
        if [[ "$state" == "running" ]]; then
            echo "Instance $instance_id is now running."
            break
    	else
		echo "Instance is still not up..."
	fi
        sleep 2
    done
}

install_aws_cli
create_instance "${ami_id}" "${instance_type}" "${key_name}" "${subnet_id}" "${security_group_ids}" "${instance_name}"
