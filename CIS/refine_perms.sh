#!/bin/bash

# Function to set permissions for given directory
set_perms() {
    directory="$1"
    owner="$2"
    perms="$3"
    if [[ "$(stat -c %U:%G "$directory")" != "$owner" ]] || [[ "$(stat -c %a "$directory")" != "$perms" ]]; then
        chown "$owner" "$directory"
        chmod "$perms" "$directory"
    fi
}

echo "Configuring permissions on /etc/cron..."
# Set permissions for cron directories
set_perms "/etc/cron.hourly" "root:root" "0700"
set_perms "/etc/cron.daily" "root:root" "0700"
set_perms "/etc/cron.weekly" "root:root" "0700"
set_perms "/etc/cron.monthly" "root:root" "0700"

echo "Setting permissions for passwd, group, shadow backup files..."
# Set permissions for passwd, group, shadow backup files
set_perms "/etc/passwd-" "root:root" "0600"
set_perms "/etc/group-" "root:root" "0600"

# Function to remove '+' entries
remove_plus_entries() {
    file="$1"
    if grep -q '^\+' "$file"; then
        sed -i '/^\+/d' "$file"
    fi
}

echo "Remove '+' entries from /etc/passwd /etc/shadow /etc/group..."
# Remove '+' entries
remove_plus_entries "/etc/passwd"
remove_plus_entries "/etc/shadow"
remove_plus_entries "/etc/group"

echo "CIS vulnerabilities fixed"