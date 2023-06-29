#!/bin/bash

# Disable USB Storage
if ! /sbin/modprobe -n -v usb-storage | grep -q "install /bin/true" ; then
  echo "install usb-storage /bin/true" > /etc/modprobe.d/usb_storage.conf
  rmmod usb-storage
fi

# Ensure sudo commands use pty
if ! grep -q "^Defaults.*use_pty" /etc/sudoers ; then
  echo "Defaults use_pty" >> /etc/sudoers
fi

# Ensure sudo log file exists
if ! grep -q "^Defaults.*logfile=" /etc/sudoers ; then
  echo 'Defaults logfile="/var/log/sudo.log"' >> /etc/sudoers
fi

# Ensure AIDE is installed
if ! dpkg -s aide >/dev/null 2>&1; then
  apt install -y aide aide-common
  aideinit
fi

# Ensure filesystem integrity is regularly checked
if ! crontab -u root -l | grep -q "/usr/bin/aide.wrapper --config /etc/aide/aide.conf --check"; then
  echo "0 5 * * * /usr/bin/aide.wrapper --config /etc/aide/aide.conf --check" | crontab -u root -
fi

# Ensure permissions on bootloader config are configured
if ! stat -L /boot/grub/grub.cfg | grep -q "Access: (0600/-rw-------)  Uid: (    0/    root)   Gid: (    0/    root)"; then
  chown root:root /boot/grub/grub.cfg
  chmod og-rwx /boot/grub/grub.cfg
fi

# Ensure address space layout randomization (ASLR) is enabled
if ! sysctl kernel.randomize_va_space | grep -q "= 2"; then
  echo "kernel.randomize_va_space = 2" >> /etc/sysctl.conf
  sysctl -w kernel.randomize_va_space=2
fi

echo "All fixes applied where necessary."
