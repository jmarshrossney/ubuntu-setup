#!/bin/bash
set -euo pipefail

# The official .deb. The AppImage fails Ubuntu's AppArmor profile, which
# expects the binary at /opt/Obsidian/obsidian where the .deb puts it.
# https://github.com/obsidianmd/obsidian-releases/releases

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Newest release with an amd64 .deb. Not /releases/latest, since some
# releases are mobile-only. Not `grep -m1`, see latest_github_tag in lib.sh.
url=$(curl -fsSL "https://api.github.com/repos/obsidianmd/obsidian-releases/releases?per_page=20" \
    | tr ',' '\n' \
    | awk -F'"' '/browser_download_url.*obsidian_.*_amd64\.deb/ && !u { u = $4 } END { print u }')

if [[ -z "$url" ]]; then
    echo "no amd64 .deb found in the last 20 obsidian releases" >&2
    exit 1
fi

echo "Fetching ${url}"
curl -fsSL "$url" -o "${tmp}/obsidian.deb"

# apt-get rather than dpkg -i, so dependencies are resolved.
sudo apt-get install -qy "${tmp}/obsidian.deb"

echo "Installed: $(dpkg-query -W -f='${Version}' obsidian)"
