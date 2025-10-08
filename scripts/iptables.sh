#!/bin/bash

set -euo pipefail

SAVE_DIR="/etc/iptables"
GLOBAL_DIR="/etc/network/if-pre-up.d"
#-------------------------

echo "
-----------NAVIGATION-----------

1) Default settings iptables
2) Configure SSH
3) Set ICMP
4) Save iptables $SAVE_DIR/<rules>
5) Global save after reboot
6) Load rules from $SAVE_DIR
q) Exit
--------------------------------
"
echo -n "Select number: "
read option

function setDefault {
	iptables -P INPUT DROP
	echo "[INFO] Chain input DROP"
	sleep 2
	iptables -P FORWARD DROP
	echo "[INFO] Chain forward DROP"
	sleep 2

	iptables -P OUTPUT ACCEPT
	echo "[INFO] Chain output ACCEPT"
	sleep 2
	iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	echo "[INFO] Established connections allowed"
	echo "-----------------------------------"
	echo "[INFO] Default settings completed"
}
function setSSh {
	echo -n "[INFO] Enter the port: "
	read port
	iptables -A INPUT -p tcp --dport $port -j ACCEPT
	sleep 2
	echo "[INFO] SSH port assigned"
}
function setICMP {
	echo "[INFO] Process..."
	sleep 2
	iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
	iptables -A INPUT -p icmp --icmp-type 0 -j ACCEPT
	echo "[INFO] Ping was assigned"
}

function getFile {
	echo -n "[INFO] Type file name: "
	read file_name
	sleep 2
	iptables-save > $SAVE_DIR/$file_name
	echo "[INFO] The file $file_name was saved successfully"
}

function getSave {
	if [[ -d "$SAVE_DIR" ]]; 
	then
		getFile
	else
		echo "[INFO] Creating a directory..."
		sleep 2
		mkdir $SAVE_DIR
		getFile
	fi
}


function writeGlobal {
       	echo -n "[INFO] Type script name: "
	read scriptname
	echo "[INFO] Creating a script..."
	sleep 2
	echo "[INFO] Getting list of files with rules iptables from $SAVE_DIR"
	sleep 2
	echo "----------------------------------------------"
	ls $SAVE_DIR
	echo "----------------------------------------------"
	echo -n "[INFO] What rules do you want to save? Need a name file in $SAVE_DIR: "
	read rulesfile
	if [ -e "$SAVE_DIR/$rulesfile" ];
	then
		echo "[INFO] Wait..."
		sleep 2
		cat > "$GLOBAL_DIR/$scriptname" << EOF
#!/bin/bash

/sbin/iptables-restore < /etc/iptables/$rulesfile
EOF
	

	chmod +x "$GLOBAL_DIR/$scriptname"
	echo "[INFO] The script is ready!"
	else
		echo "[INFO] Error! File not found"
		exit 0;
	fi
	

}

function loadRules {
	echo "[INFO] Getting rules..."
	echo "---------------------------"
	ls $SAVE_DIR
	echo "---------------------------"
	echo -n "[INFO] Select file: "
	read fileselected
	if [ -e $SAVE_DIR/$fileselected ];
	then
		echo "[INFO] File found! Wait..."
		sleep 2
		iptables-restore < $SAVE_DIR/$fileselected
		echo "[INFO] Success!"
	else
		echo "[INFO] Error! File not found!"
	fi
}

case $option in
	1) setDefault
		exit 0
		;;
	2)
		setSSh
		exit 0
		;;
	3)
		setICMP
		exit 0
		;;
	4) 
		getSave
		exit 0
		;;
	5)
		writeGlobal
		exit 0
		;;
	6)
		loadRules
		exit 0
		;;
	q)
		echo "[INFO] Quit..."
		exit 0
		;;
	*)	echo "[INFO] Error! Wrong key!"
	       	exit 0
		;;
esac






