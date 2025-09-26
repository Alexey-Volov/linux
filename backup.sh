#!/bin/bash

set -euo pipefail

DATE=$(date +%F)
DIR="/home"
ARCHIVE="/backup/home_$DATE.tar.gz"

tar -czf $ARCHIVE $DIR

echo "Successful copying"
