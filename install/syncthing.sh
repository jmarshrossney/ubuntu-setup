#!/bin/bash
set -euo pipefail

# From the Ubuntu archive. If devices on different Ubuntu releases start
# reporting incompatible protocol versions, switch every machine to the
# upstream repo:
#
#   sudo mkdir -p /etc/apt/keyrings
#   sudo curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg \
#       https://syncthing.net/release-key.gpg
#   echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] \
#       https://apt.syncthing.net/ syncthing stable" \
#       | sudo tee /etc/apt/sources.list.d/syncthing.list
sudo apt-get update -qq
sudo apt-get install -qy syncthing

# Runs as a user service. Skipped where there is no user systemd (containers).
if systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user enable --now syncthing.service
else
    echo "no user systemd instance; enable it yourself with:" >&2
    echo "  systemctl --user enable --now syncthing.service" >&2
fi
