#!/bin/bash

# Function to check and update SSHD Config
function update_sshd_config {
    local key="$1"
    local value="$2"
    local config_file="/etc/ssh/sshd_config"

    if grep -q -P "^#\?\s*$key" "$config_file"; then
        # Uncomment the existing configuration line
        sed -i -r "s/^#\s*($key\s+).*/\1$value/" "$config_file"
    elif grep -q -P "^$key" "$config_file"; then
        # Change the existing configuration
        sed -i -r "s/^($key\s+).*/\1$value/" "$config_file"
    else
        # Add a new configuration
        echo "$key $value" >> "$config_file"
    fi
}

# Function to uninstall package if installed
function uninstall_package {
    local package="$1"

    if dpkg -s "$package" >/dev/null 2>&1; then
        apt purge -y "$package"
    fi
}

# Ensure SSH MaxSessions is limited
update_sshd_config "MaxSessions" "10"

# Ensure rsh client is not installed
uninstall_package "rsh-client"

# Ensure telnet client is not installed
uninstall_package "telnet"

# Ensure permissions on /etc/ssh/sshd_config are configured
chown root:root /etc/ssh/sshd_config
chmod og-rwx /etc/ssh/sshd_config

# Ensure SSH X11 forwarding is disabled
update_sshd_config "X11Forwarding" "no"

# Ensure SSH MaxAuthTries is set to 4 or less
update_sshd_config "MaxAuthTries" "4"

# Restart SSH service to apply changes
systemctl restart ssh

echo "CIS vulnerabilities fixed"
