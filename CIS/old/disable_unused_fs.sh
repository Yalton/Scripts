#!/bin/bash

# List of all the filesystems to disable
FILESYSTEMS=("freevxfs" "jffs2" "hfs" "hfsplus" "squashfs" "udf" "vfat")

# Disable unnecessary filesystems
for fs in ${FILESYSTEMS[@]}; do
    MODPROBE_CONF_FILE="/etc/modprobe.d/$fs.conf"
    if [ ! -f $MODPROBE_CONF_FILE ] || ! grep -q "^install $fs /bin/true$" $MODPROBE_CONF_FILE; then
        echo "install $fs /bin/true" | sudo tee $MODPROBE_CONF_FILE
        if lsmod | grep -q "^$fs "; then
            sudo rmmod $fs
        fi
    fi
done

# Configure /tmp mount point
FSTAB_LINE="tmpfs /tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0"
if ! grep -q "^$FSTAB_LINE$" /etc/fstab; then
    echo "$FSTAB_LINE" | sudo tee -a /etc/fstab
fi

# Remount /tmp with appropriate options
if ! grep -q ' /tmp ' /proc/mounts | grep -q 'nodev'; then
    sudo mount -o remount,nodev /tmp
fi

# Configure /tmp mount point via systemd
SYSTEMD_TMP_MOUNT="/etc/systemd/system/local-fs.target.wants/tmp.mount"
if [ -f $SYSTEMD_TMP_MOUNT ] && ! grep -q "^Options=mode=1777,strictatime,noexec,nodev,nosuid$" $SYSTEMD_TMP_MOUNT; then
    sudo sed -i 's/^Options=.*/Options=mode=1777,strictatime,noexec,nodev,nosuid/' $SYSTEMD_TMP_MOUNT
fi

# If the tmp.mount file exists, enable it
if [ -f $SYSTEMD_TMP_MOUNT ]; then
    sudo systemctl unmask tmp.mount
    sudo systemctl enable tmp.mount
fi
