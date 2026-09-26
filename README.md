# Shell Scripting Projects

A collection of small DevOps automation projects written in Bash. They target Debian/Ubuntu Linux (they use `apt-get` and `systemctl`).

| Project | Script | Purpose |
|---|---|---|
| Create EC2 instance | [automate-create-ec2/create-ec2.sh](automate-create-ec2/create-ec2.sh) | Installs the AWS CLI if needed and launches an EC2 instance |
| Rotating backups | [backup-rotating-script/backup.sh](backup-rotating-script/backup.sh) | Zips a directory and keeps only the 5 newest backups |
| Deploy Django app | [deploy-django-app/deploy-app.sh](deploy-django-app/deploy-app.sh) | Clones a Django notes app and runs it in Docker |

## 1. automate-create-ec2

Creates an EC2 instance and waits until it is `running`.

**What it does**
1. Validates that all 6 arguments are given.
2. Installs `curl`, `unzip` and the AWS CLI v2 if `aws` is missing.
3. Runs `aws ec2 run-instances` with a `Name` tag.
4. Polls the instance state until `running`. It stops with an error if the instance ends up terminated or stopped.

**Usage**
```bash
./create-ec2.sh <ami_id> <instance_type> <key_name> <subnet_id> <security_group_id> <instance_name>
# example
./create-ec2.sh ami-0abcdef1234567890 t2.micro my-key subnet-0123abcd sg-0123abcd my-server
```

**Requirements:** `sudo` access, and AWS credentials configured (`aws configure` or an instance role).

## 2. backup-rotating-script

Archives a directory into `backup-<timestamp>.zip` and deletes older archives so that only the 5 newest remain. Only files matching `backup-*.zip` are ever deleted.

**Usage**
```bash
./backup.sh <source_dir> <backup_dir>
# example
./backup.sh /var/log/myapp /backups/myapp
```

The backup directory is created if it does not exist. The script exits with an error if the source is missing, `zip` is not installed, or the backup fails. In that case old backups are left untouched.

**Run on a schedule with cron** (daily at 02:00):
```cron
0 2 * * * /path/to/backup.sh /var/log/myapp /backups/myapp >> /var/log/backup.log 2>&1
```

## 3. deploy-django-app

Deploys the [django-notes-app](https://github.com/LondheShubham153/django-notes-app) in a Docker container.

**What it does**
1. Clones the repo into the current directory (skipped if it already exists).
2. Installs `docker.io`, `nginx` and `docker-compose` if they are missing.
3. Enables and starts Docker and Nginx, and grants the current user access to the Docker socket.
4. Builds the `notesapp` image and runs it as the `notesapp` container on port 8000. A previous container with the same name is replaced, so the script is safe to re-run.

**Usage**
```bash
./deploy-app.sh
# app is then available at http://<host>:8000
```

Each step stops the script with an error message if it fails.

## Getting started

```bash
git clone <this-repo>
cd Shell-Scripting-Projects
chmod +x */*.sh
```
