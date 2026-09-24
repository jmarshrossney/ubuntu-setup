#!/bin/bash
set -euo pipefail

# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Latest release tarball. Pass a version to pin one, e.g. `bash neovim.sh v0.11.6`.
# https://github.com/neovim/neovim/blob/master/INSTALL.md

VERSION="${1:-latest}"
ASSET="nvim-linux-x86_64"

if [[ "$VERSION" == latest ]]; then
    url="https://github.com/neovim/neovim/releases/latest/download/${ASSET}.tar.gz"
else
    url="https://github.com/neovim/neovim/releases/download/${VERSION}/${ASSET}.tar.gz"
fi

install_release_tarball "$url" "$ASSET" "bin/nvim" "$ASSET"

"${HOME}/.local/bin/nvim" --version | awk 'NR==1'

# The python provider is pynvim, installed by python.sh.
