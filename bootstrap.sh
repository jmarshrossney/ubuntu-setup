#!/bin/bash
set -euo pipefail

# Sets up a bare machine: installs git, just and stow, clones the dotfiles,
# links them into $HOME, loads the GNOME settings, then runs `just install`.
# Safe to re-run.
#   sudo apt-get install -y git
#   git clone https://github.com/jmarshrossney/ubuntu-setup.git \
#       ~/github.com/jmarshrossney/ubuntu-setup
#   bash ~/github.com/jmarshrossney/ubuntu-setup/bootstrap.sh

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_URL="https://github.com/jmarshrossney/dotfiles.git"
DOTFILES_DIR="${HOME}/github.com/jmarshrossney/dotfiles"
BACKUP_DIR="${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

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

# Stow will not replace real files, and a fresh install has some in the way,
# such as Ubuntu's ~/.bashrc and the ~/.config/user-dirs.dirs written at first
# login. Move each one into $BACKUP_DIR. Skips what stow ignores: README.* at
# a package's top level, and .gitignore anywhere.
cd "$DOTFILES_DIR"
mapfile -t packages < <(just list)
while IFS= read -r -d '' src; do
    rel="${src#*/}"
    target="${HOME}/${rel}"
    [[ "$rel" == README.* ]] && continue
    [[ -e "$target" || -L "$target" ]] || continue
    # Already linked, directly or through a linked parent directory.
    [[ "$(realpath -m "$target")" == "$(realpath "$src")" ]] && continue
    mkdir -p "${BACKUP_DIR}/$(dirname "$rel")"
    mv "$target" "${BACKUP_DIR}/${rel}"
    echo "moved ~/${rel} to ${BACKUP_DIR}/"
done < <(find "${packages[@]}" -type f ! -name .gitignore -print0)

just link-all

# GNOME settings. Needs the desktop session's D-Bus, so skipped over ssh and
# in containers.
if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && command -v dconf >/dev/null 2>&1; then
    just dconf-load
else
    echo "no desktop session; load the GNOME settings later with:" >&2
    echo "  just --justfile ${DOTFILES_DIR}/justfile dconf-load" >&2
fi

cd "$REPO_ROOT"
just install
