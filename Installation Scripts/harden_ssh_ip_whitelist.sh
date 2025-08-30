#!/bin/bash
echo "Disabling Port 22 SSH unless whitelisted"
#sudo iptables -A INPUT -p tcp -s 100.64.0.0/16 --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Whitelisted IPs
WHITELIST=("100.64.0.0/16" "216.58.104.207/16")

# Block all SSH by default
sudo iptables -A INPUT -p tcp --dport 22 -j DROP

# Allow SSH from whitelist
for ip in "${WHITELIST[@]}"; do
  sudo iptables -I INPUT -p tcp -s "$ip" --dport 22 -j ACCEPT
done
