#!/bin/bash

set -euo pipefail

MAIN_DIR="/etc/wireguard"

function showNav {
	
	echo "------------------------"
	echo "
1) Install Wireguard
2) Add wg0.conf
q) Quit
	"
	echo "------------------------"
}

function getWireguard {
	apt install wireguard -y
	echo ""
	echo "Wireguard was installed"
}

while true; do
	showNav
	echo -n "Select a number: "
	read option

	case $option in 
		1) getWireguard ;;
		*) echo "Exit..."
			exit
		       	;;
		q) echo "Exit..."
			exit
			;;
	esac
done
