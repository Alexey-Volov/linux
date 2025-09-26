#!/bin/bash

set -euo pipefail

apt update && apt upgrade -y >> /var/log/update.log
