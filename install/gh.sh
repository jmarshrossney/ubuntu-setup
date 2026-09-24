#!/bin/bash
set -euo pipefail

# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Latest release tarball. Pass a version to pin one, e.g. `bash gh.sh 2.86.0`.
VERSION="${1:-$(latest_github_tag cli/cli)}"

if [[ -z "$VERSION" ]]; then
    echo "could not work out the latest gh version" >&2
    exit 1
fi

install_release_tarball \
    "https://github.com/cli/cli/releases/download/v${VERSION}/gh_${VERSION}_linux_amd64.tar.gz" \
    "gh_${VERSION}_linux_amd64" \
    "bin/gh" \
    'gh_*_linux_amd64'

"${HOME}/.local/bin/gh" --version | awk "NR==1"
