#!/bin/bash

echo "Starting to fix CIS vulnerabilities..."

# Ensure permissions on /etc/crontab are configured
echo "Checking /etc/crontab permissions..."
if [[ "$(stat -c "%a" /etc/crontab)" -ne 700 || "$(stat -c "%u" /etc/crontab)" -ne 0 || "$(stat -c "%g" /etc/crontab)" -ne 0 ]]; then
  echo "Fixing /etc/crontab permissions..."
  chown root:root /etc/crontab
  chmod og-rwx /etc/crontab
fi

# Ensure permissions on /etc/cron.d are configured
echo "Checking /etc/cron.d permissions..."
if [[ "$(stat -c "%a" /etc/cron.d)" -ne 700 || "$(stat -c "%u" /etc/cron.d)" -ne 0 || "$(stat -c "%g" /etc/cron.d)" -ne 0 ]]; then
  echo "Fixing /etc/cron.d permissions and creating necessary files..."
  rm /etc/cron.deny
  rm /etc/at.deny
  touch /etc/cron.allow
  touch /etc/at.allow
  chmod og-rwx /etc/cron.allow /etc/at.allow
  chown root:root /etc/cron.allow /etc/at.allow
fi

# Ensure at/cron is restricted to authorized users
echo "Checking at/cron restrictions..."
if [ ! -f /etc/cron.allow ] || [ ! -f /etc/at.allow ] || [ -f /etc/at.deny ] || [ -f /etc/cron.deny ]; then
  echo "Adjusting at/cron restrictions..."
  rm /etc/cron.deny
  rm /etc/at.deny
  touch /etc/cron.allow
  touch /etc/at.allow
  chmod og-rwx /etc/cron.allow /etc/at.allow
  chown root:root /etc/cron.allow /etc/at.allow
fi

AUDIT_RULES_PATH="/etc/audit/audit.rules"
AUDIT_DIR_PATH="/etc/audit"

echo "Checking audit directory..."
if [ ! -d "$AUDIT_DIR_PATH" ]; then
  echo "Creating audit directory..."
  mkdir "$AUDIT_DIR_PATH"
fi

echo "Checking audit rules file..."
if [ ! -f "$AUDIT_RULES_PATH" ]; then
  echo "Creating audit rules file..."
  touch "$AUDIT_RULES_PATH"
fi

# Ensure changes to system administration scope (sudoers) is collected
echo "Checking sudoers scope audit rules..."
if ! grep -q "/etc/sudoers -p wa -k scope" /etc/audit/audit.rules; then
  echo "Adding sudoers scope audit rule..."
  echo "-w /etc/sudoers -p wa -k scope" >> /etc/audit/audit.rules
fi
if ! grep -q "/etc/sudoers.d/ -p wa -k scope" /etc/audit/audit.rules; then
  echo "Adding sudoers.d scope audit rule..."
  echo "-w /etc/sudoers.d/ -p wa -k scope" >> /etc/audit/audit.rules
fi

# Ensure system administrator actions (sudolog) are collected
echo "Checking sudolog audit rules..."
SUDO_LOG_PATH=/var/log/sudo.log  # You should replace with your sudo log path
if ! grep -q "$SUDO_LOG_PATH -p wa -k actions" /etc/audit/audit.rules; then
  echo "Adding sudolog audit rule..."
  echo "-w $SUDO_LOG_PATH -p wa -k actions" >> /etc/audit/audit.rules
fi

echo "CIS vulnerabilities fixed"
