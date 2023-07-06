#!/bin/bash

# Function to disable service if it's currently running
disable_service() {
    service=$1
    if systemctl is-enabled --quiet "$service"; then
        echo "Disabling $service"
        systemctl --now disable "$service"
    else
        echo "$service is already disabled"
    fi
}

# Function to uninstall package if it's currently installed
uninstall_package() {
    package=$1
    if dpkg -s "$package" &> /dev/null; then
        echo "Uninstalling $package"
        apt-get purge -y "$package"
    else
        echo "$package is not installed"
    fi
}

# Function to disable module if it's currently loaded
disable_module() {
    module=$1
    if lsmod | grep --quiet "^${module} "; then
        echo "Disabling $module"
        echo "install $module /bin/true" > "/etc/modprobe.d/${module}.conf"
    else
        echo "$module is already disabled"
    fi
}

echo "Disabling Uneeded services..."
# Disabling services
disable_service "avahi-daemon"
disable_service "cups"

# Uninstalling packages
uninstall_package "nis"

# Disabling modules
disable_module "dccp"
disable_module "sctp"
disable_module "rds"
disable_module "tipc"

echo "CIS vulnerabilities fixed"
