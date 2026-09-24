#!/bin/bash
set -euo pipefail

# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

apt_install apt

sudo apt-get dist-upgrade -qy
sudo apt-get autoremove -qy
