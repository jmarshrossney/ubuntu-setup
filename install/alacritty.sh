#!/bin/bash
set -euo pipefail

sudo apt-get update -qqy
sudo apt-get install -qy alacritty

# Register as an x-terminal-emulator alternative. To select it:
#   sudo update-alternatives --config x-terminal-emulator
sudo update-alternatives --install /usr/bin/x-terminal-emulator \
    x-terminal-emulator "$(command -v alacritty)" 50
