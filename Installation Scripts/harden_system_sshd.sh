#!/bin/bash
# This script disables root login and root SSH login

# 1. Change root's shell to /sbin/nologin
sudo sed -i '/^root:/s#:/bin/bash#:/sbin/nologin#' /etc/passwd

# 2. Set 'PermitRootLogin no' in SSH config
sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config

# 3. Restart the sshd service
sudo systemctl restart sshd

echo "Root login and SSH root access have been disabled."
