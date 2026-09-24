#!/bin/bash
set -euo pipefail

# Installs git, just and stow, then clones the dotfiles. On a bare machine:
#   sudo apt-get install -y git
#   git clone https://github.com/jmarshrossney/ubuntu-setup.git
#   bash ubuntu-setup/bootstrap.sh

DOTFILES_URL="https://github.com/jmarshrossney/dotfiles.git"
DOTFILES_DIR="${HOME}/github.com/jmarshrossney/dotfiles"

sudo apt-get update -qq
sudo apt-get install -qy ca-certificates curl git just stow

if [[ -d "${DOTFILES_DIR}/.git" ]]; then
    echo "dotfiles already cloned at ${DOTFILES_DIR}"
else
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    # Switch to ssh once the machine has a key:
    #   git -C "${DOTFILES_DIR}" remote set-url origin git@github.com:jmarshrossney/dotfiles.git
    git clone "$DOTFILES_URL" "$DOTFILES_DIR"
fi

cat <<MSG

Next, link the dotfiles. Ubuntu's own ~/.bashrc is in the way of the bash
package, and stow will not overwrite it:

  mv ~/.bashrc ~/.bashrc.ubuntu-default
  cd ${DOTFILES_DIR}
  just check-all   # dry run; nothing else should conflict
  just link-all

Then come back here and run: just all
MSG
