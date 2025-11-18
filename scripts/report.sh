#!/bin/bash

REPORT="$HOME/sysreport_$(hostname)_$(date +%F_%H-%M).txt"

{
	echo "==========================="
	echo "SYSTEM REPORT ($(hostname))"
	echo "==========================="
	echo "Date: $(date)"
	echo "USER: $USER"
	echo "---------------------------"A
	echo ""
	echo "=== OS and core ==="
	lsb_release -a 2>/dev/null || cat /etc/os-release
	uname -a
	
	echo ""
	echo "=== DATA ==="
	echo "CPU:"
	lscpu | grep -E 'Model name|CPU\(s\)|Thread|Core'
	echo ""
	echo "MEMORY:"
	free -h
	echo ""
	echo "DISKS:"
	lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
	echo ""
	echo "File System:"
	df -hT | grep -v tmpfs
	
	echo ""
	echo "=== NETWORK ==="
	ip -brief address
	echo ""
	echo "ROUTES:"
	ip route show
	echo ""
	echo "DNS-Servers:"
	grep "nameserver" /etc/resolv.conf

	echo ""
	echo "Process:"
	echo "Uptime: $(uptime -p)"
	echo "load average: $(uptime | awk -F 'load average:' '{print $2}')"
	echo "TOP-5 CPU:"
	ps -eo pid,comm,%cpu --sort=-%cpu | head -6
	echo ""
	echo "TOP-5 MEMORY"
	ps -eo pid,comm,%mem --sort=-%mem | head -6

	echo ""
	echo "=== Active networks ==="
	sudo ss -tulnp 2>/dev/null | head -10

	echo ""
	echo "=== last logins ==="
	last -n 5
	
	echo ""
	echo "update system"
	if command -v apt &> /dev/null; then
		apt list --upgradable 2>/dev/null | grep -v "Listing" || echo "All packages is update"
	fi

} > "$REPORT"






