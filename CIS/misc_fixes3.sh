#!/bin/bash

# Update PASS_MAX_DAYS parameter
current_pass_max_days=$(grep -P '^PASS_MAX_DAYS' /etc/login.defs | awk '{print $2}')
if (( current_pass_max_days > 365 )); then
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 365/' /etc/login.defs
fi

# Update PASS_MIN_DAYS parameter
current_pass_min_days=$(grep -P '^PASS_MIN_DAYS' /etc/login.defs | awk '{print $2}')
if (( current_pass_min_days < 7 )); then
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/' /etc/login.defs
fi

# Set the default password inactivity period
current_inactive=$(useradd -D | grep -P '^INACTIVE' | awk -F'=' '{print $2}')
if (( current_inactive > 30 )); then
    useradd -D -f 30
fi

# Set the root user default group to GID 0
root_gid=$(grep -P '^root' /etc/passwd | cut -d: -f4)
if (( root_gid != 0 )); then
    usermod -g 0 root
fi

# Update umask parameters
for file in /etc/bash.bashrc /etc/profile /etc/profile.d/*.sh; do
    if grep -q -P 'umask\s*\d{3}' $file; then
        current_umask=$(grep -P 'umask\s*\d{3}' $file | awk '{print $2}')
        if (( current_umask < 027 )); then
            sed -i "s/umask $current_umask/umask 027/" $file
        fi
    else
        echo "umask 027" >> $file
    fi
done

# Set default user shell timeout
for file in /etc/bash.bashrc /etc/profile /etc/profile.d/*.sh; do
    if grep -q -P 'readonly\s*TMOUT' $file; then
        current_timeout=$(grep -P 'readonly\s*TMOUT' $file | awk -F'=' '{print $2}')
        if (( current_timeout > 900 )); then
            sed -i "s/readonly TMOUT=$current_timeout/readonly TMOUT=900/" $file
        fi
    else
        echo "readonly TMOUT=900" >> $file
    fi
done

# Restrict access to the su command
if ! grep -q -P '^auth\s*required\s*pam_wheel.so' /etc/pam.d/su; then
    echo "auth required pam_wheel.so use_uid group=sudo" >> /etc/pam.d/su
fi
