#!/bin/bash

set -euo pipefail

SAVE_DIR="/etc/iptables"
GLOBAL_DIR="/etc/network/if-pre-up.d"
#-------------------------

echo "
1) Default settings iptables
2) Configure SSH
3) Set ICMP
4) Save iptables $SAVE_DIR/<rules>
5) Global save after reboot
q) Exit
"
echo -n "Choose number: "
read option

function setDefault {
	iptables -P INPUT DROP
	echo "input drop ON"
	sleep 2
	iptables -P FORWARD DROP
	echo "forward drop ON"
	sleep 2

	iptables -P OUTPUT ACCEPT
	echo "output accept ON"
	echo "Default settings completed"
}
function setSSh {
	echo -n "Which port? "
	read port
	iptables -A INPUT -p tcp --dport $port -j ACCEPT
	sleep 2
	echo "SSH port assigned"
}
function setICMP {
	echo "Process..."
	sleep 2
	iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
	iptables -A INPUT -p icmp --icmp-type 0 -j ACCEPT
	echo "Ping was assigned"
}

function getFile {
	echo -n "Type file name: "
	read file_name
	sleep 2
	iptables-save > $SAVE_DIR/$file_name
	echo "Success save file $file_name"
}

function getSave {
	if [[ -d "$SAVE_DIR" ]]; 
	then
		getFile
	else
		echo "Creating directory..."
		sleep 2
		mkdir $SAVE_DIR
		getFile
	fi
}


function writeGlobal {
       	echo -n "Type script name: "
	read scriptname
	echo "Creating script..."
	sleep 2
	echo "Getting list files with rules iptables from $SAVE_DIR"
	sleep 2
	echo "----------------------------------------------"
	ls $SAVE_DIR
	echo "----------------------------------------------"
	echo -n "Which rules do you want to save? Need a name file in $SAVE_DIR: "
	read rulesfile
	if [ -e "/etc/iptables/$rulesfile" ];
	then
		echo "Wait..."
		sleep 2
		cat > "$GLOBAL_DIR/$scriptname" << EOF
#!/bin/bash

#/sbin/iptables-restore < /etc/iptables/$rulesfile
EOF
	

	chmod +x "$GLOBAL_DIR/$scriptname"
	echo "The script is ready!"
	else
		echo "Error! File not found"
		exit 0;
	fi
	
	echo "The script was installed"

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
		exit 0;
		;;
	q)
		echo "Quit..."
		exit 0
		;;
	*)	echo "Error! Wrong key!"
	       	exit 0
		;;
esac






