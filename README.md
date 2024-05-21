# Replace Zabbix Agent 1 with Zabbix Agent 2 Script

This Bash script automates the process of replacing Zabbix Agent 1 with Zabbix Agent 2 on Ubuntu systems. It ensures that Zabbix Agent 2 is installed and configured correctly, and if Zabbix Agent 1 is present, it will be removed.

## Features

- Checks and installs any missing dependencies.
- Adds the official Zabbix repository.
- Installs Zabbix Agent 2.
- Configures Zabbix Agent 2 using user-provided server IP and hostname.
- Removes Zabbix Agent 1 if it is installed.
- Backs up the old Zabbix Agent 1 configuration.
- Ensures the script is executed with root privileges.

## Prerequisites

- The script must be run on Ubuntu.
- You must have `sudo` privileges to execute this script.

## Usage

1. **Download the script** and make it executable:

 wget https://raw.githubusercontent.com/svds12343/zabbixagent-replace/main/replace_zabbix_agent.sh
chmod +x replace_zabbix_agent.sh


2. **Run the script** using `sudo`:
   ```bash
   sudo ./replace_zabbix_agent.sh
   ```

3. **Follow the prompts** to enter the Zabbix Server IP and the hostname for the Zabbix Agent.

## Log File

- All operations are logged to `/var/log/replace_zabbix_agent.log`.

## Detailed Steps

1. **Check for root privileges**: Stops if the script is not running as root.
2. **Check and install dependencies**: Installs `wget`, `dpkg`, `apt`, and `systemctl` if they are missing.
3. **Replace Zabbix Agent 1 with Zabbix Agent 2**:
   - Stops and removes Zabbix Agent 1.
   - Backs up the configuration file of Zabbix Agent 1.
   - Installs Zabbix Agent 2.
   - Configures Zabbix Agent 2 with the server IP and hostname provided by the user.
   - Starts Zabbix Agent 2 and enables it to start at boot.
4. **Handle cases where Zabbix Agent 1 is not installed**:
   - Installs and configures Zabbix Agent 2 if it is not already installed.

## Troubleshooting

- Check the log file at `/var/log/replace_zabbix_agent.log` for detailed error messages.
- Ensure you have network connectivity and access to Zabbix repositories.

---

**Replace `[URL to this script]`** with the actual URL where your script is hosted, if you are distributing it via a download link.
