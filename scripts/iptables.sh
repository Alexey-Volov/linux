#!/bin/bash

set -euo pipefail

SAVE_DIR="/etc/iptables"
GLOBAL_DIR="/etc/network/if-pre-up.d"
#-------------------------

iptables -P INPUT DROP
echo "input drop ON"
sleep 2
iptables -P FORWARD DROP
echo "forward drop ON"
sleep 2

iptables -P OUTPUT ACCEPT
echo "output accept ON"
echo "Default settings completed"

echo -n "Do you want to set SSH port? [y/n]: "
read sshans

case $sshans in
	y)	echo -n "Which port? "
		read port
	       	iptables -A INPUT -p tcp --dport $port -j ACCEPT
		echo "SSH port assigned"
		;;
	n) echo "No...next steps..."
		;;
	*) echo "Error... exit"
		exit 0
		;;

esac

sleep 2

echo -n "Do you want to set icmp? [y/n]: "
read icmpans

case $icmpans in
	y) echo "Process..."
		iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
		iptables -A INPUT -p icmp --icmp-type 0 -j ACCEPT
		echo "Ping was assigned"
		;;
	n) echo "Next steps..."
		;;
	*) echo "Error... exit"
		exit 0;
		;;
esac


echo -n "Do you want to save iptables? [y/n]: "

read ans



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
case $ans in
	y)
		getSave
		;;
	n)
		echo "Exit..."
		exit 0
		;;
	*)
		echo "Error..."
		exit 0
		;;
esac

echo -n "Do you want global save? [y/n]: "

read global_save

function writeGlobal {
       	echo -n "Type script name: "
	read scriptname
	echo "Creating script..."
	sleep 2
	echo -n "Which rules do you want to save? Need a name file in /etc/iptables: "
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
	echo "Script is ready!"
	else
		echo "Error file not found"
		exit 0;
	fi
	#!/bin/bash
	
	#/sbin/iptables-restore < /etc/iptables/$rulesfile

	#touch "$GLOBAL_DIR/$scriptname"
	

	#chmod +x "$GLOBAL_DIR/$scriptname"
	
	echo "The script was installed"



}

case $global_save in
	y) writeGlobal
		;;
	n) echo "next steps..."
		;;
	*) echo "Error...exit"
		exit 0;
		;;
esac




