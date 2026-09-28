# Shell Scripting Projects

A collection of small DevOps automation projects written in Bash. They target Debian/Ubuntu Linux (they use `apt-get` and `systemctl`).

| Project | Script | Purpose |
|---|---|---|
| Create EC2 instance | [automate-create-ec2/create-ec2.sh](automate-create-ec2/create-ec2.sh) | Installs the AWS CLI if needed and launches an EC2 instance |
| Rotating backups | [backup-rotating-script/backup.sh](backup-rotating-script/backup.sh) | Zips a directory and keeps only the 5 newest backups |
| Deploy Django app | [deploy-django-app/deploy-app.sh](deploy-django-app/deploy-app.sh) | Clones a Django notes app and runs it in Docker |
| System health monitor | [system-health-monitor/health_monitor.sh](system-health-monitor/health_monitor.sh) | Logs CPU, memory, disk and nginx status with warnings |
| Nginx log analyzer | [nginx-log-analyzer/log_analyzer.sh](nginx-log-analyzer/log_analyzer.sh) | Summarizes an nginx access log: request count, top IPs/URLs, 4xx/5xx counts |
| Linux user management | [linux-user-management/manage_users.sh](linux-user-management/manage_users.sh) | Creates users and groups in bulk from a CSV file |

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

## 6. linux-user-management

Creates Linux users in bulk from a CSV file.

**CSV format** (first line is a header and is skipped)
```csv
username,group
alice,developers
bob,testers
```

**What it does** for each line
1. Creates the group if it does not exist.
2. Creates the user with a home directory in that group, unless the user already exists.
3. Sets a random password and forces the user to change it at first login.

At the end it prints how many users were created and how many were skipped.

**Usage**
```bash
./manage_users.sh users.csv
```

**Requirements:** `sudo` access and `openssl`.

## Command reference

Every command and flag used across the scripts. The **Used in** column shows the script: `ec2` = create-ec2.sh, `backup` = backup.sh, `deploy` = deploy-app.sh, `health` = health_monitor.sh, `nginx` = log_analyzer.sh, `users` = manage_users.sh.

### Files and text processing

| Command | Flags / usage | Meaning | Used in |
|---|---|---|---|
| `cat` | `cat file` | Print a file's content | nginx, users, health |
| `wc` | `-l` | Count lines | nginx, users |
| `awk` | `'{print $1}'` | Print a column (`$1` = first, `$NF` = last) | nginx, users, health |
| `awk` | `-F,` | Use a comma as the field separator (CSV) | users |
| `awk` | `-v line=$i` | Pass a shell variable into awk | users |
| `awk` | `NR==2`, `NR<=10` | Select lines by line number | nginx, users, health |
| `awk` | `END {print NR}` | Print the total line count after reading everything | nginx |
| `awk` | `'$9 >= 400 && $9 < 500'` | Keep lines where column 9 is in a range | nginx |
| `sort` | `-r` / `-nr` | Sort in reverse / numerically in reverse | nginx |
| `uniq` | `-c` | Collapse duplicate lines and prefix each with its count | nginx |
| `sed` | `'s/%//'` | Substitute: remove the `%` character | health |
| `grep` | `-q` `-x` | Quiet (no output, only exit code); match the whole line only | deploy |
| `ls` | `-t` | List files newest first | backup |
| `ls` | `-l` | Long listing (permissions, size, date) | deploy |
| `mkdir` | `-p` | Create the directory and any parents, no error if it exists | backup |
| `rm` | `-f` | Force, ignore missing files | backup |
| `rm` | `-rf` | Remove recursively and forcefully | ec2 |
| `rm` | `--` | End of options, so filenames starting with `-` are safe | backup |
| `date` | `+%Y-%m-%d_%H-%M-%S` | Print the date/time in a custom format | backup, health |

### Archives and downloads

| Command | Flags / usage | Meaning | Used in |
|---|---|---|---|
| `zip` | `-r` | Zip a directory recursively | backup |
| `unzip` | `-q` | Quiet, no file listing | ec2 |
| `unzip` | `-o` | Overwrite existing files without asking | ec2 |
| `curl` | `-f` | Fail on HTTP errors instead of saving the error page | ec2 |
| `curl` | `-s` | Silent, no progress bar | ec2 |
| `curl` | `-S` | Still show errors when used with `-s` | ec2 |
| `curl` | `-L` | Follow redirects | ec2 |
| `curl` | `-o file` | Save output to a file | ec2 |

### Packages, services and system info

| Command | Flags / usage | Meaning | Used in |
|---|---|---|---|
| `sudo` | `sudo cmd` | Run a command as root | ec2, deploy, health, users |
| `apt-get` | `update` | Refresh the package list | deploy, health |
| `apt-get` | `install -y pkg` | Install a package, answering yes automatically | ec2, deploy, health |
| `dpkg` | `-s pkg` | Show package status; fails if not installed | deploy |
| `systemctl` | `enable --now svc` | Start a service now and on every boot | deploy |
| `systemctl` | `is-active svc` | Print `active`, `inactive`, etc. | health |
| `chown` | `chown user file` | Change the owner of a file | deploy |
| `which` | `which cmd` | Print the path of a command | health |
| `mpstat` | `1 3` | CPU stats: 1-second interval, 3 samples, plus an average | health |
| `free` | `free` | Memory usage in KB | health |
| `df` | `-h /` | Disk usage of `/` in human-readable units | health |

### Git and Docker

| Command | Flags / usage | Meaning | Used in |
|---|---|---|---|
| `git clone` | `git clone url` | Download a repository | deploy |
| `docker build` | `-t name .` | Build an image from the current directory and tag it | deploy |
| `docker run` | `-d` | Run in the background (detached) | deploy |
| `docker run` | `--name name` | Give the container a name | deploy |
| `docker run` | `-p 8000:8000` | Map host port to container port | deploy |
| `docker ps` | `-a` | List all containers, including stopped ones | deploy |
| `docker ps` | `--format '{{.Names}}'` | Print only the container names | deploy |
| `docker rm` | `-f` | Force remove a container, even if running | deploy |

### AWS CLI

| Command | Flags | Meaning | Used in |
|---|---|---|---|
| `aws --version` | | Print the installed version | ec2 |
| `aws ec2 run-instances` | `--image-id` | AMI to launch | ec2 |
| | `--instance-type` | Size, e.g. `t2.micro` | ec2 |
| | `--key-name` | SSH key pair name | ec2 |
| | `--subnet-id` | Subnet to launch in | ec2 |
| | `--security-group-ids` | Security group to attach | ec2 |
| | `--tag-specifications` | Tags to set, used here for the `Name` tag | ec2 |
| | `--query` | Filter the JSON output (JMESPath), e.g. `Instances[0].InstanceId` | ec2 |
| | `--output text` | Plain text instead of JSON | ec2 |
| `aws ec2 describe-instances` | `--instance-ids` | Which instance to look up | ec2 |
| | `--query`, `--output` | Same as above; used to read the instance state | ec2 |

### User and group management

| Command | Flags / usage | Meaning | Used in |
|---|---|---|---|
| `getent` | `group name` / `passwd name` | Look up a group or user; empty output means it does not exist | users |
| `groupadd` | `groupadd name` | Create a group | users |
| `useradd` | `-m` | Create the home directory | users |
| `useradd` | `-g group` | Set the user's primary group | users |
| `chpasswd` | reads `user:password` from stdin | Set a password | users |
| `passwd` | `-e user` | Expire the password, forcing a change at next login | users |
| `openssl` | `rand -base64 12` | Generate 12 random bytes, base64-encoded (used as a password) | users |

### Bash built-ins and syntax

| Item | Meaning | Used in |
|---|---|---|
| `command -v cmd` | Check whether a command exists (prints its path) | ec2, backup |
| `echo -e` | Print and interpret escape sequences such as `\n` | ec2, deploy, nginx, users |
| `mapfile -t arr` | Read lines into an array, dropping the trailing newline | backup |
| `local var` | Variable that exists only inside the function | ec2, deploy, backup |
| `sleep 5` | Wait 5 seconds | ec2 |
| `cd dir` | Change directory | deploy |
| `case ... esac` | Match a value against several patterns | ec2 |
| `>>` | Append output to a file | health, users |
| `2>&1`, `>/dev/null` | Redirect errors to the same place as output; discard output | ec2, backup, deploy |
| `$( ... )` | Command substitution: use a command's output as a value | ec2, backup, nginx, health, users |
| `${arr[@]:5}` | Array slice from index 5 onward | backup |

**Special variables:** `$1`, `$2`... (arguments), `$@` (all arguments), `$#` (argument count), `$0` (script name), `$?` (exit code of the last command), `$USER` (current user).

**Test operators** (inside `[ ]`):

| Operator | Meaning | Used in |
|---|---|---|
| `-z str` | String is empty | ec2, nginx, health, users |
| `-d path` | Path is a directory | backup, deploy |
| `-eq`, `-ne` | Numbers equal / not equal | ec2, backup, users |
| `-ge`, `-lt` | Greater or equal / less than | ec2, backup, health |
| `=`, `==` | String equals | ec2, health |

## Getting started

```bash
git clone <this-repo>
cd Shell-Scripting-Projects
chmod +x */*.sh
```
