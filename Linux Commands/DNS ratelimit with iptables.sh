#!/bin/bash
# This script limits the queries per second to 5/s
# with a burst rate of 15/s and does not require
# buffer space changes

# Requests per second
RQS="5"

# Requests per 7 seconds
RQH="35"

iptables --flush
iptables -A INPUT -p udp --dport 53 -m state --state NEW -m recent --set --name DNSQF --rsource
iptables -A INPUT -p udp --dport 53 -m state --state NEW -m recent --update --seconds 1 --hitcount ${RQS} --name DNSQF --rsource -j DROP
iptables -A INPUT -p udp --dport 53 -m state --state NEW -m recent --set --name DNSHF --rsource
iptables -A INPUT -p udp --dport 53 -m state --state N
