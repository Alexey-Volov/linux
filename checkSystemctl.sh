#!/bin/bash

set -euo pipefail

HOME_DIR=$HOME
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
check=$(systemctl --failed | grep "loaded units" | awk '{print $1}')

if [ "$check" -gt 0 ] 
then
	echo -e "${RED}Error system! log file is here $HOME_DIR/error_system.log${NC}"
	systemctl --failed >> $HOME_DIR/error_system.log
else
	echo -e "${GREEN}Errors not found${NC}"
fi
