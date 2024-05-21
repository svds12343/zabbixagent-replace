#!/bin/bash

# Enhanced script to replace Zabbix Agent 1 with Zabbix Agent 2 on Ubuntu with additional features

LOG_FILE="/var/log/replace_zabbix_agent.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check if a package is installed
is_package_installed() {
    dpkg -l "$1" &> /dev/null
    return $?
}

# Function to check if a service is active
is_service_active() {
    systemctl is-active --quiet "$1"
    return $?
}

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    log "This script must be run as root. Please use sudo to run this script."
    exit 1
fi

# Function to get Zabbix server information from the user
get_zabbix_info() {
    read -p "Enter the Zabbix Server IP: " zabbix_server_ip
    read -p "Enter the Hostname for this Zabbix Agent: " zabbix_agent_hostname
}

# Path to the Zabbix Agent configuration file
CONFIG_PATH="/etc/zabbix/zabbix_agent2.conf"

# Check for script dependencies and attempt installation if missing
check_dependencies() {
    local missing=0
    for needed in wget dpkg apt systemctl; do
        if ! command -v $needed &> /dev/null; then
            log "Missing dependency: $needed. Attempting to install..."
            apt-get install -y $needed
            if [ $? -ne 0 ]; then
                log "Failed to install missing dependency: $needed"
                missing=1
            fi
        fi
    done
    return $missing
}

# Add Zabbix official repository and install Zabbix Agent 2
install_zabbix_agent2() {
    log "Adding Zabbix repository..."
    wget -q https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu22.04_all.deb
    dpkg -i zabbix-release_6.0-4+ubuntu22.04_all.deb
    apt update

    log "Installing Zabbix Agent 2..."
    apt install -y zabbix-agent2
    if [ $? -eq 0 ]; then
        log "Zabbix Agent 2 has been successfully installed."
    else
        log "Error: Failed to install Zabbix Agent 2."
        return 1
    fi
}

# Function to configure Zabbix Agent 2
configure_zabbix_agent2() {
    log "Configuring Zabbix Agent 2..."
    if [ -f "$CONFIG_PATH" ]; then
        mv "$CONFIG_PATH" "${CONFIG_PATH}.bak"
    fi

    {
        echo "Server=$zabbix_server_ip"
        echo "ServerActive=$zabbix_server_ip"
        echo "Hostname=$zabbix_agent_hostname"
    } >> "$CONFIG_PATH"

    log "Zabbix Agent 2 configuration has been updated."
}

# Function to remove Zabbix Agent 1
remove_zabbix_agent1() {
    log "Removing Zabbix Agent 1..."
    apt purge -y zabbix-agent
    if [ $? -eq 0 ]; then
        log "Zabbix Agent 1 has been successfully removed."
    else
        log "Error: Failed to remove Zabbix Agent 1."
        return 1
    fi
}

# Main process
log "Starting the Zabbix Agent replacement process..."

# Check and install dependencies
if check_dependencies; then
    log "All dependencies are installed."
else
    log "Some dependencies could not be installed. Please check the logs."
    exit 1
fi

# Check for Zabbix Agent 1
if is_package_installed zabbix-agent; then
    log "Zabbix Agent 1 is installed. Preparing to replace it with Zabbix Agent 2..."

    # Get Zabbix server information from user
    get_zabbix_info

    # Stop Zabbix Agent 1 service if it is running
    if is_service_active zabbix-agent; then
        log "Stopping Zabbix Agent 1 service..."
        systemctl stop zabbix-agent
        if [ $? -ne 0 ]; then
            log "Warning: Failed to stop Zabbix Agent 1 service."
        fi
    fi

    # Backup the current Zabbix Agent 1 configuration file
    if [ -f "/etc/zabbix/zabbix_agentd.conf" ]; then
        log "Backing up the Zabbix Agent 1 configuration..."
        cp "/etc/zabbix/zabbix_agentd.conf" "/etc/zabbix/zabbix_agentd.conf.bak"
        if [ $? -ne 0 ]; then
            log "Error: Failed to backup Zabbix Agent 1 configuration."
            exit 1
        fi
    else
        log "Warning: No Zabbix Agent 1 configuration file found at /etc/zabbix/zabbix_agentd.conf. Continuing without backup."
    fi

    # Install Zabbix Agent 2
    if install_zabbix_agent2; then
        # Configure Zabbix Agent 2
        configure_zabbix_agent2

        # Enable and start Zabbix Agent 2 service
        log "Enabling and starting Zabbix Agent 2 service..."
        systemctl enable zabbix-agent2
        systemctl restart zabbix-agent2
        if [ $? -eq 0 ]; then
            log "Zabbix Agent 2 is running."

            # Remove Zabbix Agent 1
            if remove_zabbix_agent1; then
                log "Zabbix Agent 1 has been replaced by Zabbix Agent 2 successfully."
            else
                log "Zabbix Agent 2 was installed, but there was an error removing Zabbix Agent 1."
                exit 1
            fi
        else
            log "Error: Failed to start Zabbix Agent 2 service."
            exit 1
        fi
    else
        log "Installation of Zabbix Agent 2 failed. Zabbix Agent 1 was not removed."
        exit 1
    fi
else
    log "Zabbix Agent 1 is not installed. Checking for Zabbix Agent 2..."

    # Get Zabbix server information from user
    get_zabbix_info

    # Check if Zabbix Agent 2 is already installed
    if is_package_installed zabbix-agent2; then
        log "Zabbix Agent 2 is already installed. Configuring Zabbix Agent 2..."

        # Configure Zabbix Agent 2
        configure_zabbix_agent2

        log "Zabbix Agent 2 has been configured successfully."
    else
        log "Neither Zabbix Agent 1 nor Zabbix Agent 2 is installed. Installing Zabbix Agent 2..."

        # Install Zabbix Agent 2 directly
        if install_zabbix_agent2; then
            # Configure Zabbix Agent 2
            configure_zabbix_agent2

            log "Zabbix Agent 2 has been installed and configured successfully."
        else
            log "Failed to install Zabbix Agent 2."
            exit 1
        fi
    fi
fi
