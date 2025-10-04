#!/bin/bash

set -euo pipefail

SAVE_DIR="/etc/iptables"
FILE_NAME="rules.v5"
iptables -P INPUT DROP
echo "input drop ON"
sleep 2
iptables -P FORWARD DROP
echo "forward drop ON"
sleep 2

iptables -P OUTPUT ACCEPT
echo "output accept ON"
echo "Default settings completed"

echo -n "Starting set port ssh, type here "
read sshport

iptables -A INPUT -p tcp --dport $sshport -j ACCEPT

echo "ssh port is succesfuly set"

sleep 2

echo -n "Do you want to save iptables? [y/n]: "

read ans

function getSave {
	if [[ -d "$SAVE_DIR" ]]; 
	then
		echo "directory is here..."
		sleep 2
		iptables-save > $SAVE_DIR/$FILE_NAME
		echo "Success save file $FILE_NAME"
	else
		echo "nothing dir...creating"
		sleep 2
		mkdir $SAVE_DIR
		iptables-save > $SAVE_DIR/$FILE_NAME		
		echo "Success save file $FILE_NAME"
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
		;;
esac






