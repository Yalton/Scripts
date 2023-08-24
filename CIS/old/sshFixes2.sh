#!/bin/bash

# Disabling PermitUserEnvironment
sudo sed -i '/^PermitUserEnvironment/c\PermitUserEnvironment no' /etc/ssh/sshd_config

# Only strong ciphers are used
sudo sed -i '/^Ciphers/c\Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr' /etc/ssh/sshd_config

# Only strong MAC algorithms are used
sudo sed -i '/^MACs/c\MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256' /etc/ssh/sshd_config

# Only strong Key Exchange algorithms are used
sudo sed -i '/^KexAlgorithms/c\KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256' /etc/ssh/sshd_config

# SSH Idle Timeout Interval is configured
sudo sed -i '/^ClientAliveInterval/c\ClientAliveInterval 300' /etc/ssh/sshd_config
sudo sed -i '/^ClientAliveCountMax/c\ClientAliveCountMax 0' /etc/ssh/sshd_config

# SSH LoginGraceTime is set to one minute or less
sudo sed -i '/^LoginGraceTime/c\LoginGraceTime 60' /etc/ssh/sshd_config

# SSH access is limited
# Add your user and group lists here
sudo sed -i '/^AllowUsers/c\AllowUsers <userlist>' /etc/ssh/sshd_config
sudo sed -i '/^AllowGroups/c\AllowGroups <grouplist>' /etc/ssh/sshd_config
sudo sed -i '/^DenyUsers/c\DenyUsers <userlist>' /etc/ssh/sshd_config
sudo sed -i '/^DenyGroups/c\DenyGroups <grouplist>' /etc/ssh/sshd_config

# SSH warning banner is configured
sudo sed -i '/^Banner/c\Banner /etc/issue.net' /etc/ssh/sshd_config

# SSH PAM is enabled
sudo sed -i '/^UsePAM/c\UsePAM yes' /etc/ssh/sshd_config

# SSH AllowTcpForwarding is disabled
sudo sed -i '/^AllowTcpForwarding/c\AllowTcpForwarding no' /etc/ssh/sshd_config

# SSH MaxStartups is configured
sudo sed -i '/^MaxStartups/c\MaxStartups 10:30:60' /etc/ssh/sshd_config

# Restart the SSH service to effect the changes
sudo systemctl restart sshd
