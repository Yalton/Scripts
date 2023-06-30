#!/bin/bash

# function to check and install libpam
function check_and_install_libpam {
  dpkg -s libpam-pwquality &> /dev/null
  if [ $? -ne 0 ]; then
    apt install libpam-pwquality -y
  fi
}

# function to check and configure password policy
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

# function to check and configure login attempts
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

# function to check and configure password history
function check_and_configure_password_history {
  if ! grep -q "^password.*pam_pwhistory.so.*remember=5" /etc/pam.d/common-password; then
    echo "password required pam_pwhistory.so remember=5" >> /etc/pam.d/common-password
  fi
}

# function to update password age and inactivity period
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

# function to update umask parameters and user shell timeout
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

# function to restrict access to the su command
function restrict_su_command {
  if ! grep -q -P '^auth\s*required\s*pam_wheel.so' /etc/pam.d/su; then
      echo "auth required pam_wheel.so use_uid group=sudo" >> /etc/pam.d/su
  fi
}

check_and_install_libpam
check_and_configure_password_policy
check_and_configure_login_attempts
check_and_configure_password_history
update_password_policy
update_umask_and_timeout
restrict_su_command

echo "Password policies successfully updated"
