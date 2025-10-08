#!/bin/bash

set -euo pipefail

SAVE_DIR="/etc/iptables"
GLOBAL_DIR="/etc/network/if-pre-up.d"

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
#-------------------------

if [ $EUID != 0 ]
then
	echo "Permission denied!"
	exit 0;
fi
function showMenu {

echo "
-----------NAVIGATION-----------

1) Default settings iptables
2) Configure SSH
3) Set ICMP
4) Save iptables $SAVE_DIR/<rules>
5) Global save after reboot
6) Load rules from $SAVE_DIR
7) Check iptables
8) Delete saved rules
q) Exit
--------------------------------
"
}

function setDefault {
	iptables -P INPUT DROP
	echo -e "${GREEN}[INFO] Chain input DROP${NC}"
	sleep 2
	iptables -P FORWARD DROP
	echo -e "${GREEN}[INFO] Chain forward DROP${NC}"
	sleep 2

	iptables -P OUTPUT ACCEPT
	echo -e "${GREEN}[INFO] Chain output ACCEPT${NC}"
	sleep 2
	iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	echo -e "${GREEN}[INFO] Established connections allowed${NC}"
	echo "-----------------------------------"
	echo -e "${GREEN}[INFO] Default settings completed${NC}"
}
function setSSh {
	echo -n "[INFO] Enter the port: "
	read port
	iptables -A INPUT -p tcp --dport $port -j ACCEPT
	sleep 2
	echo -e "${GREEN}[INFO] SSH port assigned${NC}"
}
function setICMP {
	echo -e "${GREEN}[INFO] Process...${NC}"
	sleep 2
	iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
	iptables -A INPUT -p icmp --icmp-type 0 -j ACCEPT
	echo -e "${GREEN}[INFO] Ping was assigned${NC}"
}

function getFile {
	echo -n "[INFO] Type file name: "
	read file_name
	sleep 2
	iptables-save > $SAVE_DIR/$file_name
	echo -e "${GREEN}[INFO] The file $file_name was saved successfully${NC}"
}

function getSave {
	if [[ -d "$SAVE_DIR" ]]; 
	then
		getFile
	else
		echo -e "${GREEN}[INFO] Creating a directory...${NC}"
		sleep 2
		mkdir $SAVE_DIR
		getFile
	fi
}


function writeGlobal {
       	echo -n "[INFO] Type script name: "
	read scriptname
	echo -e "${GREEN}[INFO] Creating a script...${NC}"
	sleep 2
	echo -e "${GREEN}[INFO] Getting list of files with rules iptables from $SAVE_DIR${NC}"
	sleep 2
	echo "----------------------------------------------"
	ls $SAVE_DIR
	echo "----------------------------------------------"
	echo -n "[INFO] What rules do you want to save? Need a name file in $SAVE_DIR: "
	read rulesfile
	if [ -e "$SAVE_DIR/$rulesfile" ];
	then
		echo -e "${GREEN}[INFO] Wait...${NC}"
		sleep 2
		cat > "$GLOBAL_DIR/$scriptname" << EOF
#!/bin/bash

/sbin/iptables-restore < /etc/iptables/$rulesfile
EOF
	

	chmod +x "$GLOBAL_DIR/$scriptname"
	echo -e "${GREEN}[INFO] The script is ready!${NC}"
	else
		echo -e "${RED}[INFO] Error! File not found${NC}"
		exit 0;
	fi
	

}

function loadRules {
	echo -e "${GREEN}[INFO] Getting rules...${NC}"
	echo "---------------------------"
	ls $SAVE_DIR
	echo "---------------------------"
	echo -n "[INFO] Select file: "
	read fileselected
	if [ -e $SAVE_DIR/$fileselected ];
	then
		echo -e "${GREEN}[INFO] File found! Wait...${NC}"
		sleep 2
		iptables-restore < $SAVE_DIR/$fileselected
		echo "${GREEN}[INFO] Success!${NC}"
	else
		echo -e "${RED}[INFO] Error! File not found!${NC}"
	fi
}

function checkiptables {
	clear
	iptables -L -n -v
}
function deleteRules {
	clear
       	echo "
1) Delete rules from $SAVE_DIR
2) Delete global rules from $GLOBAL_DIR
	"	
	echo -n "Select a number: "
	read opt


	case $opt in
		1) 	echo -e "${GREEN}[INFO]Getting list rules...${NC}"
		sleep 2
		echo "----------------------------------------"
		ls $SAVE_DIR
		echo "----------------------------------------"
		echo -n "Select file: "
		read deletefile
		TARGET="$SAVE_DIR/$deletefile"
		if [ -e $TARGET ];
		then
			rm -rf $TARGET
			echo -e "${GREEN}[INFO] The file $deletefile was deleted${NC}"
		else
			echo -e "${RED}[INFO] Error! File not found!${NC}"
		fi
		;;
		2) 	echo -e "${GREEN}[INFO]Getting list rules...${NC}"
			sleep 2
			echo "----------------------------------------"
		ls $GLOBAL_DIR
		echo "----------------------------------------"
		echo -n "Select file: "
		read deletefile
		GLOBAL_TARGET="$GLOBAL_DIR/$deletefile"
		if [ -e $GLOBAL_TARGET ];
		then
			rm -rf $GLOBAL_TARGET
			echo -e "${GREEN}[INFO] The file $deletefile was deleted${NC}"
		else
			echo -e "${RED}[INFO] Error! File $deletefile not found!${NC}"
		fi
		;;
		*)	echo "Exit..."
		       	exit 0
			;;
	esac


}
while true; do
	showMenu
	echo -n "Select number: "
	read option

	case $option in
		1) setDefault ;;
		2) setSSh ;;
		3) setICMP ;;
		4) getSave ;;
		5) writeGlobal ;;
		6) loadRules ;;
		7) checkiptables ;;
		8) deleteRules ;;
		q) 
			echo -e "${GREEN}[INFO] Quit...${NC}"
			exit 0
			;;
		*) echo -e "${RED}[INFO] Error! Wrong key!${NC}"
	esac

	echo ""
	echo "[INFO] Press Enter to continue..."
	read
	
done






