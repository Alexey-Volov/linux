#!/bin/bash

#Script to identify a failed connection.

set -euo pipefail

filelog="$HOME/connection.log"

sudo journalctl -u ssh | awk '/Connection closed/{print $0}' | tail -20 >> $filelog

date >> $filelog
