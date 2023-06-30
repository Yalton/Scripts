#!/bin/bash
set -e

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

# Ensure core dumps are restricted
CORE_LIMIT_EXISTS=$(grep -Rh ^*\ hard\ core\ /etc/security/limits.conf /etc/security/limits.d || true)
SUID_DUMPABLE_EXISTS=$(grep -Rh fs.suid_dumpable /etc/sysctl.conf /etc/sysctl.d || true)
SUID_DUMPABLE_CURRENT=$(sysctl fs.suid_dumpable | awk -F' ' '{print $3}')

if [[ "$CORE_LIMIT_EXISTS" != "* hard core 0" ]]; then
  echo "* hard core 0" >> /etc/security/limits.conf
fi

if [[ "$SUID_DUMPABLE_EXISTS" != "fs.suid_dumpable = 0" ]]; then
  echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf
fi

if [[ "$SUID_DUMPABLE_CURRENT" != "0" ]]; then
  sysctl -w fs.suid_dumpable=0
fi

# Ensure all AppArmor Profiles are enforcing
APPARMOR_STATUS=$(apparmor_status)

if [[ "$APPARMOR_STATUS" =~ [1-9]+\ profiles\ are\ in\ complain\ mode || "$APPARMOR_STATUS" =~ [1-9]+\ processes\ are\ unconfined ]]; then
  aa-enforce /etc/apparmor.d/*
fi

# Ensure local login warning banner is configured properly
BANNER_CONTENT="Authorized uses only. All activity may be monitored and reported."
BANNER_EXISTS=$(cat /etc/issue || true)

if [[ "$BANNER_EXISTS" != "$BANNER_CONTENT" ]]; then
  echo "$BANNER_CONTENT" > /etc/issue
fi

# Ensure remote login warning banner is configured properly
BANNER_REMOTE_EXISTS=$(cat /etc/issue.net || true)

if [[ "$BANNER_REMOTE_EXISTS" != "$BANNER_CONTENT" ]]; then
  echo "$BANNER_CONTENT" > /etc/issue.net
fi

echo "All checks applied successfully."
echo "All fixes applied where necessary."
