#!/bin/bash

# Ensure permissions on /etc/crontab are configured
if [ $(stat -c "%a %u %g" /etc/crontab) != "700 0 0" ]; then
  chown root:root /etc/crontab
  chmod og-rwx /etc/crontab
fi

# Ensure permissions on /etc/cron.d are configured
if [ $(stat -c "%a %u %g" /etc/cron.d) != "700 0 0" ]; then
  rm /etc/cron.deny
  rm /etc/at.deny
  touch /etc/cron.allow
  touch /etc/at.allow
  chmod og-rwx /etc/cron.allow /etc/at.allow
  chown root:root /etc/cron.allow /etc/at.allow
fi

# Ensure at/cron is restricted to authorized users
if [ ! -f /etc/cron.allow ] || [ ! -f /etc/at.allow ] || [ -f /etc/at.deny ] || [ -f /etc/cron.deny ]; then
  rm /etc/cron.deny
  rm /etc/at.deny
  touch /etc/cron.allow
  touch /etc/at.allow
  chmod og-rwx /etc/cron.allow /etc/at.allow
  chown root:root /etc/cron.allow /etc/at.allow
fi

# Ensure changes to system administration scope (sudoers) is collected
if ! grep -q "/etc/sudoers -p wa -k scope" /etc/audit/audit.rules; then
  echo "-w /etc/sudoers -p wa -k scope" >> /etc/audit/audit.rules
fi
if ! grep -q "/etc/sudoers.d/ -p wa -k scope" /etc/audit/audit.rules; then
  echo "-w /etc/sudoers.d/ -p wa -k scope" >> /etc/audit/audit.rules
fi

# Ensure system administrator actions (sudolog) are collected
SUDO_LOG_PATH=/var/log/sudo.log  # You should replace with your sudo log path
if ! grep -q "$SUDO_LOG_PATH -p wa -k actions" /etc/audit/audit.rules; then
  echo "-w $SUDO_LOG_PATH -p wa -k actions" >> /etc/audit/audit.rules
fi
