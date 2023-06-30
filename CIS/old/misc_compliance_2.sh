#!/bin/bash
set -e

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
