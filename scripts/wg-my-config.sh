#!/bin/bash

set -euo pipefail

LOG_FILE="/var/log/wg-setup.log"

MAIN_DIR="/etc/wireguard"
SERVER_DIR="$MAIN_DIR/server"
PUBLIC_KEY="$SERVER_DIR/publickey.key"
PRIVATE_KEY="$SERVER_DIR/privatekey.key"
CONFIG_WG="$MAIN_DIR/wg0.conf"
SERVER_ADDRESS="10.0.0.1/24"

SERVICE="wg-quick@wg0"

CLIENT_DIR="$MAIN_DIR/clients"


GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"

if [ $EUID != 0 ]
then
	echo "Permission denied!"
	exit 0;
fi

function log {
	echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

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
	log "Wireguard was installed"
}

function restartWireguard {
	clear
	echo "------------------------------------------"
	echo -e "${GREEN}Starting restart service...${NC}"
	sleep 1
	systemctl restart $SERVICE
	echo -e "${GREEN}Done!${NC}"
	sleep 2
	echo -e "${GREEN}Check status $SERVICE${NC}"
	echo "------------------------------------------"
	systemctl status $SERVICE
	echo "------------------------------------------"

	log "Wireguard was restarted"
}

function generateServerKey {
	echo -e "${GREEN}Generating private and public key...${NC}"
	sleep 2
	wg genkey | tee $PRIVATE_KEY | wg pubkey | tee $PUBLIC_KEY
	chmod 600 $PRIVATE_KEY
	echo -e "${GREEN}The keys was generated!${NC}"
	echo ""
	log "The server keys was generated"
}

function initServer {
	local checkKey=$(ls $SERVER_DIR/*.key 2>/dev/null | wc -l)
	if [ "$checkKey" -gt 0 ]
	then
		echo -e "${RED}ERROR! The keys is already exist!${NC}"
		return
	else
		if [ -d $SERVER_DIR ]
		then
			sleep 2
			echo ""
			generateServerKey
		else
			echo -e "${GREEN}Creating directory${NC}"
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
				echo -e "${RED}Operation canceled${NC}"
				return
			fi
		fi

		read -p "Enter your network interface: " interface
		echo -e "${GREEN}Creating config server...${NC}"
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
	echo -e "${GREEN}The config is ready${NC}"
	log "The server config was created"
	else
		echo -e "${RED}ERROR${NC}"
	fi
}

function setIpForward {
	echo -e "${GREEN}Setting forwarding...${NC}"
	sleep 2
	grep -qxF "net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
	echo -e "${GREEN}Done${NC}"
	echo -e "${GREEN}Check sysctl...${NC}"
	echo ""
	sysctl -p
}

function enableWireguard {
	echo -e "${GREEN}Enable service...${NC}"
	sleep 1
	systemctl enable wg-quick@wg0.service
	echo -e "${GREEN}Starting service...${NC}"
	sleep 1
	systemctl start wg-quick@wg0.service
	echo -e "${GREEN}Check status...${NC}"
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
	echo -e "${GREEN}Create config client...${NC}"
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
	echo -e "${GREEN}The file $clientName.conf is ready!${NC}"
	log "Created $clientName config"

}

function createClientKeys {
	read -p "Type client name: " clientName
	client="$CLIENT_DIR/$clientName"

	if [ -d $client ]
	then
		echo -e "${GREEN}Client $clientName is already exist!${NC}"
		return
	fi

	echo -e "${GREEN}Creating client directory - $clientName${NC}"
	sleep 1
	mkdir $CLIENT_DIR/$clientName
	echo -e "${GREEN}The directory and empty config was created${NC}"
	echo "-------------------------"
	echo -e "${GREEN}Generating private and public client keys...${NC}"
	
	sleep 2
	wg genkey | tee $client/privatekey.key | wg pubkey | tee $client/publickey.key
	addClientConfig
	log "Created public and private keys for $clientName"
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
		*) echo -e "${RED}Exit...${NC}"
			exit
		       	;;
		q) echo -e "${RED}Exit...${NC}"
			exit
			;;
	esac
done
