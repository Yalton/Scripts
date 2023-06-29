#!/bin/bash

# Check if libpam-pwquality is installed
dpkg -s libpam-pwquality &> /dev/null
if [ $? -eq 0 ]; then
    echo "libpam-pwquality is already installed."
else
    echo "libpam-pwquality is not installed. Installing..."
    apt install libpam-pwquality -y
fi

# Configure /etc/pam.d/common-password
grep -q "^password    requisite     pam_pwquality.so retry=3" /etc/pam.d/common-password || echo "password    requisite     pam_pwquality.so retry=3" >> /etc/pam.d/common-password

# Configure /etc/security/pwquality.conf
grep -q "^minlen = 14" /etc/security/pwquality.conf || echo "minlen = 14" >> /etc/security/pwquality.conf
grep -q "^dcredit = -1" /etc/security/pwquality.conf || echo "dcredit = -1" >> /etc/security/pwquality.conf
grep -q "^ucredit = -1" /etc/security/pwquality.conf || echo "ucredit = -1" >> /etc/security/pwquality.conf
grep -q "^ocredit = -1" /etc/security/pwquality.conf || echo "ocredit = -1" >> /etc/security/pwquality.conf
grep -q "^lcredit = -1" /etc/security/pwquality.conf || echo "lcredit = -1" >> /etc/security/pwquality.conf

# Configure /etc/pam.d/common-auth
grep -q "^auth required pam_tally2.so onerr=fail audit silent deny=5 unlock_time=900" /etc/pam.d/common-auth || echo "auth required pam_tally2.so onerr=fail audit silent deny=5 unlock_time=900" >> /etc/pam.d/common-auth

# Configure /etc/pam.d/common-account
grep -q "^account    requisite    pam_deny.so" /etc/pam.d/common-account || echo "account    requisite    pam_deny.so" >> /etc/pam.d/common-account
grep -q "^account    required    pam_tally2.so" /etc/pam.d/common-account || echo "account    required    pam_tally2.so" >> /etc/pam.d/common-account

# Configure /etc/pam.d/common-password for password reuse limitation
grep -q "^password required pam_pwhistory.so remember=5" /etc/pam.d/common-password || echo "password required pam_pwhistory.so remember=5" >> /etc/pam.d/common-password

# Set permissions on /etc/shadow
chown root:shadow /etc/shadow
chmod o-rwx,g-wx /etc/shadow

# Set permissions on /etc/group
chown root:root /etc/group
chmod 644 /etc/group

# Set permissions on /etc/gshadow
chown root:shadow /etc/gshadow
chmod o-rwx,g-rw /etc/gshadow

# Lock accounts with empty password
# python -c "
# import crypt;
# with open('/etc/shadow', 'r') as f:
#     lines = f.readlines()
# for line in lines:
#     parts = line.split(':')
#     if parts[ to the end.



# So the output might look something like this:

#!/bin/bash

# Strong passwords protect systems from being hacked through brute force methods
check_and_install_libpam() {
  dpkg -s libpam-pwquality &> /dev/null
  if [ $? -ne 0 ]; then
    apt install libpam-pwquality -y
  fi
}

check_and_configure_password_policy() {
  if ! grep -q "^password.*pam_pwquality.so.*retry=3" /etc/pam.d/common-password; then
    echo "password requisite pam_pwquality.so retry=3" >> /etc/pam.d/common-password
  fi

  sed -i "s/^#\?minlen.*/minlen = 14/" /etc/security/pwquality.conf
  sed -i "s/^#\?dcredit.*/dcredit = -1/" /etc/security/pwquality.conf
  sed -i "s/^#\?ucredit.*/ucredit = -1/" /etc/security/pwquality.conf
  sed -i "s/^#\?ocredit.*/ocredit = -1/" /etc/security/pwquality.conf
  sed -i "s/^#\?lcredit.*/lcredit = -1/" /etc/security/pwquality.conf
}

check_and_configure_login_attempts() {
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

check_and_configure_password_history() {
  if ! grep -q "^password.*pam_pwhistory.so.*remember=5" /etc/pam.d/common-password; then
    echo "password required pam_pwhistory.so remember=5" >> /etc/pam.d/common-password
  fi
}

check_and_install_libpam
check_and_configure_password_policy
check_and_configure_login_attempts
check_and_configure_password_history

echo "Password policies successfully updated"
