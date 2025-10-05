#!/bin/bash

set -euo pipefail

SAVE_DIR="/etc/iptables"
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
read sshport

case $sshport in
	y) iptables -A INPUT -p tcp --dport $sshport -j ACCEPT
		echo "SSH port assigned"
		;;
	n) echo "No...next steps..."
		;;
	*) echo "Error... exit"
		exit 0
		;;

esac

sleep 2

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






