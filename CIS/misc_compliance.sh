#!/bin/bash
set -e

function check_and_install_libpam {
  dpkg -s libpam-pwquality &> /dev/null
  if [ $? -ne 0 ]; then
    apt install libpam-pwquality -y
  fi
}

function check_and_configure_password_policy {
  if ! grep -q "^password.*pam_pwquality.so.*retry=3" /etc/pam.d/common-password; then
    echo "password requisite pam_pwquality.so retry=3" >> /etc/pam.d/common-password
  fi

  sed -i "s/^#\?minlen.*/minlen = 14/" /etc/security/pwquality.conf
  sed -i "s/^#\?dcredit.*/dcredit = -1/" /etc/security/pwquality.conf
  sed -i "s/^#\?ucredit.*/ucredit = -1/" /etc/security/pwquality.conf
  sed -i "s/^#\?ocredit.*/ocredit = -1/" /etc/security/pwquality.conf
  sed -i "s/^#\?lcredit.*/lcredit = -1/" /etc/security/pwquality.conf
}

function check_and_configure_login_attempts {
  if ! grep -q "^auth.*pam_tally2.so.*onerr=fail audit silent deny=5" /etc/pam.d/common-auth; then
    echo "auth required pam_tally2.so onerr=fail audit silent deny=5 unlock_time=900" >> /etc/pam.d/common-auth
  fi

  if ! grep -q "^account.*requisite.*pam_deny.so" /etc/pam.d/common-account; then
    echo "account    requisite    pam_deny.so" >> /etc/pam.d/common-account
  fi

  if ! grep -q "^account.*required.*pam_tally2.so" /etc/pam.d/common-account; then
    echo "account    required    pam_tally2.so" >> /etc/pam.d/common-account
  fi
}

function check_and_configure_password_history {
  if ! grep -q "^password.*pam_pwhistory.so.*remember=5" /etc/pam.d/common-password; then
    echo "password required pam_pwhistory.so remember=5" >> /etc/pam.d/common-password
  fi
}

function update_password_policy {
  current_pass_max_days=$(grep -P '^PASS_MAX_DAYS' /etc/login.defs | awk '{print $2}')
  if (( current_pass_max_days > 365 )); then
      sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 365/' /etc/login.defs
  fi

  current_pass_min_days=$(grep -P '^PASS_MIN_DAYS' /etc/login.defs | awk '{print $2}')
  if (( current_pass_min_days < 7 )); then
      sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/' /etc/login.defs
  fi

  current_inactive=$(useradd -D | grep -P '^INACTIVE' | awk -F'=' '{print $2}')
  if (( current_inactive > 30 )); then
      useradd -D -f 30
  fi
}

function update_umask_and_timeout {
  for file in /etc/bash.bashrc /etc/profile /etc/profile.d/*.sh; do
      if grep -q -P 'umask\s*\d{3}' $file; then
          current_umask=$(grep -P 'umask\s*\d{3}' $file | awk '{print $2}')
          if (( current_umask < 027 )); then
              sed -i "s/umask $current_umask/umask 027/" $file
          fi
      else
          echo "umask 027" >> $file
      fi

      if grep -q -P 'readonly\s*TMOUT' $file; then
          current_timeout=$(grep -P 'readonly\s*TMOUT' $file | awk -F'=' '{print $2}')
          if (( current_timeout > 900 )); then
              sed -i "s/readonly TMOUT=$current_timeout/readonly TMOUT=900/" $file
          fi
      else
          echo "readonly TMOUT=900" >> $file
      fi
  done
}

function restrict_su_command {
  if ! grep -q -P '^auth\s*required\s*pam_wheel.so' /etc/pam.d/su; then
      echo "auth required pam_wheel.so use_uid group=sudo" >> /etc/pam.d/su
  fi
}

# Continue with the system security enhancements

echo "Starting system security enhancements..."

# Disable USB Storage
echo "Disabling USB storage..."
if ! /sbin/modprobe -n -v usb-storage | grep -q "install /bin/true" ; then
  echo "install usb-storage /bin/true" > /etc/modprobe.d/usb_storage.conf
  if lsmod | grep -q "^usb_storage "; then
    rmmod usb_storage
  fi
fi

# Ensure sudo commands use pty
echo "Ensuring sudo commands use pty..."
if ! grep -q "^Defaults.*use_pty" /etc/sudoers ; then
  echo "Defaults use_pty" >> /etc/sudoers
fi

# Ensure sudo log file exists
echo "Ensuring sudo log file exists..."
if ! grep -q "^Defaults.*logfile=" /etc/sudoers ; then
  echo 'Defaults logfile="/var/log/sudo.log"' >> /etc/sudoers
fi

# Ensure permissions on bootloader config are configured
echo "Ensuring permissions on bootloader config are configured..."
if ! stat -L /boot/grub/grub.cfg | grep -q "Access: (0600/-rw-------)  Uid: (    0/    root)   Gid: (    0/    root)"; then
  chown root:root /boot/grub/grub.cfg
  chmod og-rwx /boot/grub/grub.cfg
fi

# Ensure address space layout randomization (ASLR) is enabled
echo "Ensuring address space layout randomization (ASLR) is enabled..."
if ! sysctl kernel.randomize_va_space | grep -q "= 2"; then
  echo "kernel.randomize_va_space = 2" >> /etc/sysctl.conf
  sysctl -w kernel.randomize_va_space=2
fi

# Ensure core dumps are restricted
echo "Ensuring core dumps are restricted..."
CORE_LIMIT_EXISTS=$(grep -Rh ^*\ hard\ core\ /etc/security/limits.conf /etc/security/limits.d || true)
SUID_DUMPABLE_EXISTS=$(grep -Rh fs.suid_dumpable /etc/sysctl.conf /etc/sysctl.d || true)
SUID_DUMPABLE_CURRENT=$(sysctl fs.suid_dumpable | awk -F' ' '{print $3}')

if [[ "$CORE_LIMIT_EXISTS" != "* hard core 0" ]]; then
  echo "*My apologies for the cutoff earlier, here's the complete final part of the script:
  hard core 0" >> /etc/security/limits.conf
fi

if [[ "$SUID_DUMPABLE_EXISTS" != "fs.suid_dumpable = 0" ]]; then
  echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf
fi

if [[ "$CORE_LIMIT_EXISTS" != "* hard core 0" ]]; then
  echo "* hard core 0" >> /etc/security/limits.conf
fi

# Check and install libpam
check_and_install_libpam

# Check and configure password policy
check_and_configure_password_policy

# Check and configure login attempts
check_and_configure_login_attempts

# Check and configure password history
check_and_configure_password_history

# Update password policy
update_password_policy

# Update umask and timeout
update_umask_and_timeout

# Restrict su command
restrict_su_command

echo "CIS vulnerabilities fixed"
