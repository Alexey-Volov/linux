#!/bin/bash

set -euo pipefail

echo "Starting update."
sudo apt update && sudo apt upgrade -y

sudo apt autoremove -y
sudo apt clean

echo "Update is done."

