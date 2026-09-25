#!/bin/bash
set -euo pipefail

# One Nerd Font, latest release. Re-running upgrades.
# FONT is the release asset name without .zip, e.g. FiraCode, Hack or
# JetBrainsMono; see https://github.com/ryanoasis/nerd-fonts/releases.
# The alacritty config in the dotfiles names the font family, so change it too.
FONT="FiraCode"

# One directory whatever FONT is, so switching fonts replaces the old one.
FONT_DIR="${HOME}/.local/share/fonts/nerd-font"

for cmd in unzip fc-cache; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "${cmd} not found; run apt.sh first" >&2
        exit 1
    fi
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT}.zip"
echo "Fetching ${url}"
curl -fsSL "$url" -o "${tmp}/font.zip"

# A fresh directory, so fonts dropped from a release do not linger.
rm -rf "$FONT_DIR"
mkdir -p "$FONT_DIR"
unzip -q "${tmp}/font.zip" '*.ttf' -d "$FONT_DIR"

fc-cache -f "$FONT_DIR"
# Fails if fontconfig cannot see the font.
fc-list : family file | grep -F "$FONT_DIR" | cut -d: -f2 | sort -u
