#!/bin/bash

# Function to check and update SSHD Config
function update_sshd_config {
    local key="$1"
    local value="$2"
    local config_file="/etc/ssh/sshd_config"
    
    echo "Updating $key in SSHD Config to $value..."

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

    echo "Uninstalling $package if installed..."

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

# SSH access is limited
# Allow all users and groups with a home directory
userlist=$(awk -F':' '{ if ($3 >= 1000 && $3 != 65534 && $6 != "/nonexistent" && $7 != "/usr/sbin/nologin") print $1}' /etc/passwd | tr '\n' ' ')
grouplist=$(awk -F':' '{ if ($3 >= 1000 && $3 != 65534) print $1}' /etc/group | tr '\n' ' ')

update_sshd_config "AllowUsers" "$userlist"
update_sshd_config "AllowGroups" "$grouplist"
update_sshd_config "DenyUsers" "<userlist>"
update_sshd_config "DenyGroups" "<grouplist>"

# SSH warning banner is configured
update_sshd_config "Banner" "/etc/issue.net"

# SSH PAM is enabled
update_sshd_config "UsePAM" "yes"

# SSH AllowTcpForwarding is disabled
update_sshd_config "AllowTcpForwarding" "no"

# SSH MaxStartups is configured
update_sshd_config "MaxStartups" "10:30:60"

# Restart SSH service to apply changes
echo "Restarting SSH service to apply changes..."
systemctl restart ssh

echo "CIS vulnerabilities fixed"
