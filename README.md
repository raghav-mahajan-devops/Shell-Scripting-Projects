# Shell Scripting Projects

A collection of small DevOps automation projects written in Bash. They target Debian/Ubuntu Linux (they use `apt-get` and `systemctl`).

📒 **[NOTES.md](NOTES.md)** explains every command and pattern used in these scripts, with examples, gotchas and interview Q&A. Read it to revise Bash.

| Project | Script | Purpose |
|---|---|---|
| Create EC2 instance | [automate-create-ec2/create-ec2.sh](automate-create-ec2/create-ec2.sh) | Installs the AWS CLI if needed and launches an EC2 instance |
| Rotating backups | [backup-rotating-script/backup.sh](backup-rotating-script/backup.sh) | Archives a directory as `.tar.gz` and keeps only the 4 newest backups |
| Deploy Django app | [deploy-django-app/deploy-app.sh](deploy-django-app/deploy-app.sh) | Clones a Django notes app and runs it in Docker |
| System health monitor | [system-health-monitor/health_monitor.sh](system-health-monitor/health_monitor.sh) | Logs CPU, memory, disk and nginx status with warnings |
| Nginx log analyzer | [nginx-log-analyzer/log_analyzer.sh](nginx-log-analyzer/log_analyzer.sh) | Summarizes an nginx access log: request count, top 5 IPs/URLs, 4xx/5xx counts |
| Linux user management | [linux-user-management/manage_users.sh](linux-user-management/manage_users.sh) | Creates users and groups in bulk from a CSV file |
| File organizer | [file_organizer/file_organizer.sh](file_organizer/file_organizer.sh) | Moves files into `images/`, `web/`, `documents/` and `others/` by their real file type |
| System information *(work in progress)* | [system_information/sysInfo.sh](system_information/sysInfo.sh) | Prints a report of OS, CPU, memory, disk and network details |

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

Archives a directory into a compressed `backup_<timestamp>.tar.gz` file, then deletes older backups so that only the **4 newest** `backup_*.tar.gz` files remain. Every step is printed to the terminal and appended to `log/log.txt`.

**What it does**
1. Checks that the source directory and the backup directory both exist. It stops with an error if either is missing.
2. Checks that `tar` is installed, and installs it with `apt` if it is not.
3. Creates `<backup_dir>/backup_YY-MM-DD-HH-MM-SS.tar.gz` from the source directory (`tar -czvf`).
4. Lists only the `backup_*.tar.gz` files in the backup directory, newest first (`ls -t`), and deletes every one after the 4th. Other files in the backup directory are never touched.

The script runs with `set -euo pipefail`, so it stops at the first failing command. If `tar` fails, no old backups are deleted.

**Usage**
```bash
cd backup-rotating-script
./backup.sh <source_dir> <backup_dir>
# example, using the sample data in this folder
./backup.sh data backup
```

Run it from inside `backup-rotating-script/`. The script log path `./log/log.txt` is relative to the current directory, and the script stops if there is no `log/` folder there.

**Example output** (trimmed)
```text
 26-11-16-14-10-26 Checking data folder exist
 26-11-16-14-10-26 Data folder exist
 26-11-16-14-10-26 Checking backup folder exist
 26-11-16-14-10-26 backup folder exist
 26-11-16-14-10-26 checking tar is installed ...
 26-11-16-14-10-26 Tar is already installed
data/
data/file1.txt
data/file2.txt
 26-11-16-14-10-26 Backup is successfull
 26-11-16-14-10-26 Deleting the old backups
 26-11-16-14-10-26 file to be removed backup_26-11-15-10-25-23.tar.gz
 26-11-16-14-10-26 old backup files are deleted successfully
```

**Change how many backups are kept:** edit `backup_to_keep=4` at the top of the script.

**Restore a backup**
```bash
tar -xzvf backup/backup_26-11-15-10-26-37.tar.gz -C /path/to/restore
```

**Run on a schedule with cron** (daily at 02:00):
```cron
0 2 * * * cd /path/to/backup-rotating-script && ./backup.sh /var/log/myapp /backups/myapp >/dev/null 2>&1
```
The `cd` is needed because of the relative `log/` path. Terminal output can be discarded because the script already writes its own log.

**Known limitations**
- The backup directory is not created automatically. Create it first with `mkdir -p`.
- Running without arguments fails with `$1: unbound variable` instead of printing the usage message. `set -u` stops the script before the argument check is reached.
- If `tar` has to be installed, the archive is not created in that run. Run the script again.
- The script prints two debug numbers before deleting: the total number of backups and how many will be removed.

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
## 5. nginx-log-analyzer

Reads an nginx access log and prints a summary report to the terminal. The results and each step of the script are also appended, with a timestamp, to `log/log.txt`.

**What it reports**
- Total number of requests (one log line = one request)
- Top 5 client IPs, most frequent first
- Top 5 requested URLs, most frequent first
- Number of 4xx (client error) responses
- Number of 5xx (server error) responses

**How it works**
1. Checks that exactly one argument is given and that the file exists.
2. Counts lines with `wc -l`.
3. Finds the top IPs/URLs with `awk '{print $1}' | sort | uniq -c | sort -nr`, keeping the first 5.
4. Counts errors with `awk '$9 >= 400 && $9 < 500'` (4xx) and `awk '$9 >= 500 && $9 < 600'` (5xx).

It assumes the standard nginx combined log format: column 1 is the client IP, column 7 is the requested URL, and column 9 is the HTTP status code.

**Usage**
```bash
cd nginx-log-analyzer
./log_analyzer.sh <path_to_nginx_log>
# example, using the sample log in this folder (500 requests)
./log_analyzer.sh nginx.log
# a real server log (usually needs sudo to read)
sudo ./log_analyzer.sh /var/log/nginx/access.log
```

Run it from inside `nginx-log-analyzer/`. The script log path `./log/log.txt` is relative to the current directory, and the script stops if there is no `log/` folder there.

**Example output** (from the sample `nginx.log`)
```text
Total no of request: 500

Most Frequent Ips

Ip : 192.168.1.10
Ip : 10.0.0.5
Ip : 203.0.113.45
Ip : 198.51.100.23
Ip : 192.168.1.25

Most Famous Urls

Url: /
Url: /login
Url: /api/users
Url: /static/css/style.css
Url: /dashboard

Total 400 erros : 81

Total 500 erros : 16
```

**Example `log/log.txt` entries**
```text
26-11-16-14-10-24 : Checking the location of log file is given
26-11-16-14-10-24 : File Exist
26-11-16-14-10-24 : All requirements meet starting the script
26-11-16-14-10-24 : Ip : 192.168.1.10
26-11-16-14-10-24 : Url: /
26-11-16-14-10-24 : Total 400 erros : 81
26-11-16-14-10-24 : Total 500 erros : 16
```

**Known limitations**
- Running without arguments fails with `$1: unbound variable` instead of printing the usage message. `set -u` stops the script before the argument check is reached.
- If the log file does not exist, the script exits with code 1 but prints nothing to the terminal. The reason is only written to `log/log.txt`.
- The top IPs and URLs are listed without their request counts.
- The total request count is the line count, so blank lines would be counted as requests.

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

## 7. file_organizer

Moves the files in a folder into category folders based on their real file type, not their extension. Every step is printed to the terminal and appended to `log/log.txt`.

**How files are sorted**

The script runs `file -b <name>` on each file and uses the first word of the result, for example `JPEG` from `JPEG image data, ...`. The `-b` flag leaves the file name out of the result, so names with spaces are handled correctly.

| `file` reports | Moved to | Typical files |
|---|---|---|
| `JPEG`, `PNG` | `images/` | `.jpg`, `.png` |
| `HTML`, or `ASCII`/`Unicode` text in a file whose name ends in `.css` | `web/` | `.html`, `.css` |
| `PDF`, `Microsoft` | `documents/` | `.pdf`, `.docx`, `.xlsx`, `.pptx` |
| anything else | `others/` | `.txt`, `.csv`, shell scripts, subfolders |

**What it does**
1. Checks that exactly one argument is given and that the folder exists.
2. Lists the folder with `ls` and logs the file count and each file name.
3. For each entry, works out its type with `file -b` and picks a category folder.
4. The `move_file` function creates that folder if it is missing (`mkdir -p`) and moves the entry into it with `mv`. If a file with the same name is already in the target folder, it is **skipped** and logged, never overwritten.

The category folders are created in the **current directory**, not inside the folder being organized. Files are **moved**, so the source folder is empty afterwards.

**Usage**
```bash
cd file_organizer
./file_organizer.sh <folder_to_organize>
# example: work on a copy so the sample files stay in messy_folder
cp -r messy_folder test_folder
./file_organizer.sh test_folder
```

Running it directly on `messy_folder` moves the sample files out of it, and git will show them as deleted.

Run it from inside `file_organizer/`. The script log path `./log/log.txt` is relative to the current directory, and the script stops if there is no `log/` folder there.

**Result with the sample files**
```text
images/     133859201093936930.jpg  image.png
web/        cybersecurity_roadmap_2026.html  error.html
documents/  DevOps_Learning_Plan_Tracker.xlsx  Roadmap_topic_map.pdf
```

**Example output** (trimmed)
```text
26-11-17-15-18-49: Arguments are given proceeding next...
26-11-17-15-18-49: messy_folder exist in current directory proceeding next...
26-11-17-15-18-49: no of files 6
FileName :image.png
fileType: PNG
26-11-17-15-18-49: Folder images exist moving to next step
26-11-17-15-18-49: Moving image.png into images folder
26-11-17-15-18-49: File image.png is moved to images folder successfully
FileName :Roadmap_topic_map.pdf
fileType: PDF
26-11-17-15-18-49: Folder documents not exist, creating it
26-11-17-15-18-49: File Roadmap_topic_map.pdf is moved to documents folder successfully
```

**Requirements:** the `file` command. It is preinstalled on most Ubuntu systems; minimal images and containers may need `sudo apt-get install -y file`.

**Known limitations**
- Running without arguments fails with `$1: unbound variable` instead of printing the usage message. `set -u` stops the script before the argument check is reached.
- Skipped files stay in the source folder. Rename them and run the script again to move them.

## 8. system_information *(work in progress)*

Prints a one-page report about the machine: OS, CPU, memory, disks and network interfaces. It only reads information and changes nothing.

**What it reports**

| Section | Values | Commands used |
|---|---|---|
| System | Hostname, OS name, kernel version, uptime | `hostname`, `. /etc/os-release`, `uname -r`, `uptime -p` |
| CPU | Model name, number of cores, load average | `lscpu`, `nproc`, `uptime` |
| Memory | Total, used, available, swap total and used | `free -h` |
| Disk | Size, used, free and use % of every filesystem | `df -h` |
| Network | Interface name, IP, MAC address, RX and TX packet counts | `ifconfig` |

Each value is printed as an aligned row with `printf "%-10s : %s\n"`.

**Usage**
```bash
cd system_information
./sysInfo.sh
```

**Requirements:** Linux. The network table uses `ifconfig`, which comes from the `net-tools` package (`sudo apt-get install -y net-tools`).

**Example output** (from Ubuntu 24.04 on WSL, trimmed)
```text
==================================================
     SYSTEM INFORMATION REPORT
     26-11-20 09:56:05
==================================================

Hostname   : <your hostname>
OS         : Ubuntu 24.04.5 LTS
Kernel     : 6.18.58.1-microsoft-standard-WSL2
Uptime     : up 1 day, 14 hours, 51 minutes

CPU
--------------------------------------------------
Model Name : Intel(R) Core(TM) i5-1240P
cores      : 16
Cpu Usage  :
load average : 0.21, 0.33, 0.20

MEMORY
--------------------------------------------------
Total      : 7.6Gi
Used       : 1.6Gi
Available  : 6.0Gi
Usage      :  Pending to implment
Swap Total : 2.0Gi
Swap Used  : 0B

MEMORY
--------------------------------------------------
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdd       1007G  7.2G  949G   1% /
...
Interface  Ip address          Mac Address         RX         TX
,docker0:   172.17.0.1         86:16:b5:37:90:06    0          0
eth0:      192.168.203.139    00:15:5d:af:84:ed    648683     77927
lo:        127.0.0.1          00:15:5d:af:84:ed    657755     657755
```

**Known issues** (seen in the output above)
- **CPU usage** is empty and **memory usage %** is not implemented yet.
- The disk section is titled `MEMORY` instead of `DISK`.
- The network header prints a stray `,` before the first interface. The `printf` line has a comma after the format string.
- `lo` shows the MAC address of `eth0`. The awk variable `mac` is not reset for each interface, and `lo` has no MAC of its own.
- **Model name** is cut short. The awk command prints only columns 5–7, so `12th Gen Intel(R) Core(TM) i5-1240P` becomes `Intel(R) Core(TM) i5-1240P`. Other CPU names will be cut differently.
- **Load average** reads columns 10–12 of `uptime`. Those positions move when uptime is less than one day, and then only one value is printed. `awk -F'load average: ' '{print $2}'` always works.
- Interface names keep the trailing `:` (for example `eth0:`).
- A `log()` function is defined but not used yet. The `log/` folder is empty, and git does not track empty folders. Add a `log/.gitkeep` file before you start using `log()`, or a fresh clone will not have the folder.

## Command reference

Every command, flag and Bash pattern used in these scripts is explained in **[NOTES.md](NOTES.md)**. It covers:

- strict mode, variables, quoting, arguments, exit codes, tests, loops, functions and arrays
- tables of commands grouped by task, each with the scripts that use it
- an `awk` guide and copy-paste recipes, for example "top 5 IPs" or "keep the N newest backups"
- gotchas taken from real bugs in this repo, plus self-test interview questions

## Getting started

```bash
git clone <this-repo>
cd Shell-Scripting-Projects
chmod +x */*.sh
```
