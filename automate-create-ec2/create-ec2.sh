#! /bin/bash


<< task
Automate the process of creating a EC2 instance
task

function install_aws_cli {

	is_aws_install=$(command -v aws)
	
	is_zip_install=$(command -v zip)
	
        if [ -z "${is_aws_install}" ];then
                echo -e "downlading the aws-cli \n"
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
		
		sudo ./aws/install
		
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

install_aws_cli



