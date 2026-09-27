# Shell Scripting Projects

A collection of small DevOps automation projects written in Bash. They target Debian/Ubuntu Linux (they use `apt-get` and `systemctl`).

| Project | Script | Purpose |
|---|---|---|
| Create EC2 instance | [automate-create-ec2/create-ec2.sh](automate-create-ec2/create-ec2.sh) | Installs the AWS CLI if needed and launches an EC2 instance |
| Rotating backups | [backup-rotating-script/backup.sh](backup-rotating-script/backup.sh) | Zips a directory and keeps only the 5 newest backups |
| Deploy Django app | [deploy-django-app/deploy-app.sh](deploy-django-app/deploy-app.sh) | Clones a Django notes app and runs it in Docker |
| System health monitor | [system-health-monitor/health_monitor.sh](system-health-monitor/health_monitor.sh) | Logs CPU, memory, disk and nginx status with warnings |
| Nginx log analyzer | [nginx-log-analyzer/log_analyzer.sh](nginx-log-analyzer/log_analyzer.sh) | Summarizes an nginx access log: request count, top IPs/URLs, 4xx/5xx counts |

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

## 4. system-health-monitor

Checks the health of the machine and appends one line per metric to `logs.txt` in the current directory. A metric is logged as `[WARNING]` when it crosses its threshold, otherwise as `[INFO]`. The script then prints the whole log file.

| Check | How it is measured | Warning when |
|---|---|---|
| CPU usage | `mpstat 1 3` (average of 3 samples) | >= 50% |
| Memory usage | `free` (used / total) | >= 75% |
| Disk usage on `/` | `df -h /` | >= 70% |
| nginx service | `systemctl is-active nginx` | `inactive` |

`sysstat` (which provides `mpstat`) is installed automatically with `apt-get` if it is missing, so `sudo` access is needed on first run.

**Usage**
```bash
./health_monitor.sh
```

**Example log output**
```text
2026-09-26 10:00:01 [INFO] CPU: 12
2026-09-26 10:00:01 [INFO] MEM: 41
2026-09-26 10:00:01 [WARNING] DISK: 78
2026-09-26 10:00:01 [INFO] NGINX: active
```

**Run every 5 minutes with cron**
```cron
*/5 * * * * cd /path/to/system-health-monitor && ./health_monitor.sh >/dev/null 2>&1
```
The `cd` matters because the log file is written to the current directory.

**Known limitations**
- The description in the script mentions network checks and alerts to an administrator. Neither is implemented yet; warnings only go to the log file.
- Only `inactive` nginx is flagged. States such as `failed` are logged as `[INFO]`.
- The first line of the script has the shebang and the comment block joined on one line, so the `<<COMMENT` block does not work as intended.

## 5. nginx-log-analyzer

Reads an nginx access log and prints a summary report to the terminal.

**What it reports**
- Total number of requests
- Top 10 client IPs
- Top 10 requested URLs
- Number of 4xx (client error) responses
- Number of 5xx (server error) responses

**Usage**
```bash
./log_analyzer.sh <path_to_nginx_log>
# example
./log_analyzer.sh /var/log/nginx/access.log
```

The script exits with an error if no log file path is given. It assumes the standard nginx combined log format, where column 1 is the client IP, column 7 is the requested URL, and column 9 is the HTTP status code.

## Getting started

```bash
git clone <this-repo>
cd Shell-Scripting-Projects
chmod +x */*.sh
```
