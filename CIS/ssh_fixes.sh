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

# Ensure permissions on /etc/ssh/sshd_config are configured
echo "Configuring permissions on /etc/ssh/sshd_config..."
chown root:root /etc/ssh/sshd_config
chmod og-rwx /etc/ssh/sshd_config

# Ensure SSH X11 forwarding is disabled
update_sshd_config "X11Forwarding" "no"

# Ensure SSH MaxAuthTries is set to 4 or less
update_sshd_config "MaxAuthTries" "4"

# Disable PermitUserEnvironment
update_sshd_config "PermitUserEnvironment" "no"

# Use only strong ciphers
update_sshd_config "Ciphers" "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr"

# Use only strong MAC algorithms
update_sshd_config "MACs" "hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256"

# Use only strong Key Exchange algorithms
update_sshd_config "KexAlgorithms" "curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256"

# SSH Idle Timeout Interval is configured
update_sshd_config "ClientAliveInterval" "300"
update_sshd_config "ClientAliveCountMax" "0"

# SSH LoginGraceTime is set to one minute or less
update_sshd_config "LoginGraceTime" "60"

# SSH access is limited
# Add your user and group lists here
update_sshd_config "AllowUsers" "<userlist>"
update_sshd_config "AllowGroups" "<grouplist>"
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
