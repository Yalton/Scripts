#!/bin/bash

# function to check if a partition is already mounted
function is_mounted {
    mountpoint -q $1
}

# function to remount a partition with certain options
function remount_partition {
    PARTITION=$1
    OPTION=$2

    echo "Checking if $PARTITION needs remounting with $OPTION..."
    # if the partition is not already mounted with the option
    if ! grep -q "[[:space:]]$PARTITION[[:space:]]" /proc/mounts | grep -q "$OPTION"; then
        sudo mount -o remount,$OPTION $PARTITION
        echo "Remounted $PARTITION with $OPTION"
    fi
}

# function to add an option to /etc/fstab for a partition
function add_option_to_fstab {
    PARTITION=$1
    OPTION=$2

    echo "Checking if $OPTION needs to be added to /etc/fstab for $PARTITION..."
    # if the option is not already in /etc/fstab for the partition
    if ! grep -q "^$PARTITION[[:space:]]" /etc/fstab | grep -q "$OPTION"; then
        sudo sed -i "/^$PARTITION[[:space:]]/ s/defaults/defaults,$OPTION/" /etc/fstab
        echo "Added $OPTION to /etc/fstab for $PARTITION"
    fi
}

# function to handle separate partition recommendation
function handle_separate_partition {
    DIRECTORY=$1

    echo "Checking if $DIRECTORY is a separate partition..."
    if ! is_mounted $DIRECTORY; then
        echo "WARNING: $DIRECTORY is not a separate partition."
        echo "For improved security, consider creating a separate partition for this directory."
    fi
}

echo "Starting security enhancements..."

# List of all the filesystems to disable
FILESYSTEMS=("freevxfs" "jffs2" "hfs" "hfsplus" "squashfs" "udf" "vfat")

echo "Disabling unnecessary filesystems..."
# Disable unnecessary filesystems
for fs in ${FILESYSTEMS[@]}; do
    MODPROBE_CONF_FILE="/etc/modprobe.d/$fs.conf"
    echo "Checking if $fs filesystem is disabled..."
    if [ ! -f $MODPROBE_CONF_FILE ] || ! grep -q "^install $fs /bin/true$" $MODPROBE_CONF_FILE; then
        echo "install $fs /bin/true" | sudo tee $MODPROBE_CONF_FILE
        if lsmod | grep -q "^$fs "; then
            sudo rmmod $fs
        fi
    fi
done

echo "Finished disabling filesystems."

echo "Remounting partitions with specific options and adding those options to /etc/fstab..."

remount_partition "/tmp" "nosuid"
add_option_to_fstab "/tmp" "nosuid"
remount_partition "/tmp" "noexec"
add_option_to_fstab "/tmp" "noexec"
remount_partition "/var/tmp" "nodev"
add_option_to_fstab "/var/tmp" "nodev"
remount_partition "/var/tmp" "nosuid"
add_option_to_fstab "/var/tmp" "nosuid"
remount_partition "/var/tmp" "noexec"
add_option_to_fstab "/var/tmp" "noexec"
remount_partition "/home" "nodev"
add_option_to_fstab "/home" "nodev"
remount_partition "/dev/shm" "noexec"
add_option_to_fstab "/dev/shm" "noexec"

echo "Finished remounting and updating /etc/fstab."

echo "Configuring /tmp mount point..."

FSTAB_LINE="tmpfs /tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0"
if ! grep -q "^$FSTAB_LINE$" /etc/fstab; then
    echo "$FSTAB_LINE" | sudo tee -a /etc/fstab
fi

echo "Configuring /tmp mount point via systemd..."

SYSTEMD_TMP_MOUNT="/etc/systemd/system/local-fs.target.wants/tmp.mount"
if [ -f $SYSTEMD_TMP_MOUNT ] && ! grep -q "^Options=mode=1777,strictatime,noexec,nodev,nosuid$" $SYSTEMD_TMP_MOUNT; then
    sudo sed -i 's/^Options=.*/Options=mode=1777,strictatime,noexec,nodev,nosuid/' $SYSTEMD_TMP_MOUNT
fi

# If the tmp.mount file exists, enable it
if [ -f $SYSTEMD_TMP_MOUNT ]; then
    echo "Enabling tmp.mount..."
    sudo systemctl unmask tmp.mount
    sudo systemctl enable tmp.mount
fi

echo "Handling separate partition recommendations..."

handle_separate_partition "/var"
handle_separate_partition "/var/tmp"
handle_separate_partition "/var/log"
handle_separate_partition "/var/log/audit"
handle_separate_partition "/home"

echo "All checks applied successfully."
echo "All fixes applied where necessary."
