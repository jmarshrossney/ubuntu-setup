#!/bin/bash
set -euo pipefail

# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Latest release .deb, installed to /opt/quarto with /usr/local/bin/quarto.
# Pass a version to pin one, e.g. `bash install/quarto.sh 1.10.18`.
# https://github.com/quarto-dev/quarto-cli/releases
VERSION="${1:-$(latest_github_tag quarto-dev/quarto-cli)}"

if [[ -z "$VERSION" ]]; then
    echo "could not work out the latest quarto version" >&2
    exit 1
fi

# Remove the old tarball install, which would shadow /usr/local/bin on PATH.
stale_link="${HOME}/.local/bin/quarto"
if [[ -L "$stale_link" && "$(readlink -f "$stale_link")" == "${HOME}/.local/opt/"* ]]; then
    echo "removing the old tarball install: ${stale_link}"
    rm -f "$stale_link"
fi
find "${HOME}/.local/opt" -maxdepth 1 -name 'quarto-*' -exec rm -rf {} + 2>/dev/null || true

# Skip the 143MB download if this version is installed. Must come after the
# cleanup, or `command -v` could find the old symlink.
installed=""
if command -v quarto >/dev/null 2>&1; then
    installed=$(quarto --version)
fi

if [[ "$installed" == "$VERSION" ]]; then
    echo "quarto ${VERSION} already installed"
else
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    url="https://github.com/quarto-dev/quarto-cli/releases/download/v${VERSION}/quarto-${VERSION}-linux-amd64.deb"
    echo "Fetching ${url}"
    curl -fsSL "$url" -o "${tmp}/quarto.deb"

    # apt-get rather than dpkg -i, so dependencies are resolved.
    sudo apt-get install -qy "${tmp}/quarto.deb"
fi

/usr/local/bin/quarto --version
