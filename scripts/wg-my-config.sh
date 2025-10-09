#!/bin/bash

set -euo pipefail

MAIN_DIR="/etc/wireguard"
SERVER_DIR="/etc/wireguard/server"
PUBLIC_KEY="$SERVER_DIR/publickey.key"
PRIVATE_KEY="$SERVER_DIR/privatekey.key"
CONFIG_WG="$MAIN_DIR/wg0.conf"
SERVER_ADDRESS="10.0.0.1/24"

if [ $EUID != 0 ]
then
	echo "Permission denied!"
	exit 0;
fi

function showNav {
	
	echo "------------------------"
	echo "
1) Install Wireguard
2) Generate keys
3) Create base wg0.conf
q) Quit
"
	echo "------------------------"
}


function getWireguard {
	apt install wireguard -y
	echo ""
	echo "Wireguard was installed"

	echo ""
}

function generateKey {
	echo "Generating private and public key..."
	sleep 2
	wg genkey | tee $PRIVATE_KEY | wg pubkey | tee $PUBLIC_KEY
	chmod 600 $PRIVATE_KEY
	echo "The keys was generated!"
	echo ""
	echo "Creating wg0.conf..."
	sleep 1
	touch $CONFIG_WG
	echo "The config was created"
}

function initServer {
	local checkKey=$(ls $SERVER_DIR/*.key 2>/dev/null | wc -l)
	if [ "$checkKey" -gt 0 ]
	then
		echo "ERROR! KEYS IS HERE!"
		exit 0;
	else
		if [ -d $SERVER_DIR ]
		then

			echo "dir est"
			sleep 2
			echo ""
			generateKey
		else
			echo "Creating directory"
			sleep 2
			mkdir $SERVER_DIR
			generateKey
		
		fi
	fi

}

function createConf {
	local priv_key=$(cat $PRIVATE_KEY)
	if [ -e $CONFIG_WG ]
	then
		echo "Wait..."
		sleep 2
		cat > $CONFIG_WG << EOF
[Interface]
PrivateKey = $priv_key
Address = $SERVER_ADDRESS
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o enp0s3 -j MASQUERADE

EOF
	echo "--------------------"
	echo "The config is ready"
	else
		echo "ERROR"
	fi
}

while true; do
	showNav
	echo -n "Select a number: "
	read option

	case $option in 
		1) getWireguard ;;
		2) initServer ;;
		3) createConf ;;
		*) echo "Exit..."
			exit
		       	;;
		q) echo "Exit..."
			exit
			;;
	esac
done
