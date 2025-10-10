#!/bin/bash

set -euo pipefail

MAIN_DIR="/etc/wireguard"
SERVER_DIR="$MAIN_DIR/server"
PUBLIC_KEY="$SERVER_DIR/publickey.key"
PRIVATE_KEY="$SERVER_DIR/privatekey.key"
CONFIG_WG="$MAIN_DIR/wg0.conf"
SERVER_ADDRESS="10.0.0.1/24"

SERVICE="wg-quick@wg0"

CLIENT_DIR="$MAIN_DIR/clients"

if [ $EUID != 0 ]
then
	echo "Permission denied!"
	exit 0;
fi

function showNav {
	
	echo "------------------------"
	echo "
1) Install Wireguard
2) Generate server keys
3) Create base wg0.conf
4) Set IP forward
5) Enable service
6) Create client
7) Restart service
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

function restartWireguard {
	clear
	echo "------------------------------------------"
	echo "Starting restart service..."
	sleep 1
	systemctl restart $SERVICE
	echo "Done!"
	sleep 2
	echo "Check status $SERVICE"
	echo "------------------------------------------"
	systemctl status $SERVICE
	echo "------------------------------------------"
}

function generateServerKey {
	echo "Generating private and public key..."
	sleep 2
	wg genkey | tee $PRIVATE_KEY | wg pubkey | tee $PUBLIC_KEY
	chmod 600 $PRIVATE_KEY
	echo "The keys was generated!"
	echo ""
}

function initServer {
	local checkKey=$(ls $SERVER_DIR/*.key 2>/dev/null | wc -l)
	if [ "$checkKey" -gt 0 ]
	then
		echo "ERROR! KEYS IS HERE!"
		return
	else
		if [ -d $SERVER_DIR ]
		then
			sleep 2
			echo ""
			generateServerKey
		else
			echo "Creating directory"
			sleep 2
			mkdir $SERVER_DIR
			generateServerKey
		
		fi
	fi

}

function createConf {
	local priv_key=$(cat $PRIVATE_KEY)
	touch $CONFIG_WG
	if [ -e $CONFIG_WG ]
	then
		if [ -s $CONFIG_WG ]
		then
			read -p "Config $CONFIG_WG already has content. Overwrite? [y/n]: " ans
			if [ "$ans" != "y" ]
			then 
				echo "Operation canceled"
				return
			fi
		fi

		read -p "Enter your network interface: " interface
		echo "Wait..."
		sleep 2

		cat > $CONFIG_WG << EOF
[Interface]
PrivateKey = $priv_key
Address = $SERVER_ADDRESS
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $interface -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $interface -j MASQUERADE

EOF
	echo "--------------------"
	echo "The config is ready"
	else
		echo "ERROR"
	fi
}

function setIpForward {
	echo "Process..."
	sleep 2
	grep -qxF "net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
	echo "Done"
	echo "Check sysctl..."
	echo ""
	sysctl -p
}

function enableWireguard {
	echo "Enable service..."
	sleep 1
	systemctl enable wg-quick@wg0.service
	echo "Starting service..."
	sleep 1
	systemctl start wg-quick@wg0.service
	echo "Check status..."
	sleep 1
	echo "--------------------------------"
	systemctl status  wg-quick@wg0.service
	echo "--------------------------------"


}

function addClientConfig {
	read -p "Type address client (ex: 10.0.0.2/32): " clientAddress
	getKey=$(cat $client/publickey.key)
	getPrivateKey=$(cat $client/privatekey.key)
	configClient="$client/$clientName.conf"
	serv_key=$(cat $PUBLIC_KEY)
	cat >> "$CONFIG_WG" << EOF
# Client - $clientName
[Peer]
PublicKey = $getKey
AllowedIPs = $clientAddress
EOF
	echo "Client was added to config server!"
	sleep 2
	restartWireguard
	
	echo "----------------------------------"
	echo "Create config client..."
	read -p "Type IP address server: " server_address
	touch $configClient
	sleep 1

	cat > "$configClient" << EOF
[Interface]
PrivateKey = $getPrivateKey
Address = $clientAddress
DNS = 8.8.8.8

[Peer]
PublicKey = $serv_key
Endpoint = $server_address:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 20
EOF
	echo "----------------------------------"
	echo "The file $configClient is ready!"

}

function createClientKeys {
	read -p "Type client name: " clientName
	client="$CLIENT_DIR/$clientName"

	if [ -d $client ]
	then
		echo "Client $client is already exist!"
		return
	fi

	echo "Creating client directory - $clientName"
	sleep 1
	mkdir $CLIENT_DIR/$clientName
	#client="$CLIENT_DIR/$clientName"

	echo "The directory and empty config was created"
	echo "-------------------------"
	echo "Generating private and public client keys..."
	
	sleep 2
	wg genkey | tee $client/privatekey.key | wg pubkey | tee $client/publickey.key
	echo "The private and public keys was generated"
	addClientConfig
}

function createClient {
	if [ -d $CLIENT_DIR ]
	then
		createClientKeys
		sleep 2

	else
		mkdir $CLIENT_DIR
		createClientKeys
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
		4) setIpForward ;;
		5) enableWireguard ;;
		6) createClient ;;
		7) restartWireguard ;;
		*) echo "Exit..."
			exit
		       	;;
		q) echo "Exit..."
			exit
			;;
	esac
done
