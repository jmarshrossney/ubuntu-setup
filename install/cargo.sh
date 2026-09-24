#!/bin/bash
set -euo pipefail

# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Installs rustup, then every crate in packages/cargo.txt.

# Several crates have C build scripts; fail early rather than after minutes of
# cargo output.
if ! command -v cc >/dev/null 2>&1; then
    echo "no C compiler found; run apt.sh first (cargo builds need build-essential)" >&2
    exit 1
fi

# --no-modify-path: the dotfiles own ~/.bashrc and PATH.
if ! command -v rustup >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs \
        | sh -s -- -y --no-modify-path
fi

export PATH="${HOME}/.cargo/bin:${PATH}"

rustup update

# One at a time, so one failed build does not stop the rest.
failed=()
while read -r crate; do
    echo
    echo "--- cargo install ${crate}"
    cargo install --locked "$crate" || failed+=("$crate")
done < <(package_list cargo)

if (( ${#failed[@]} > 0 )); then
    echo >&2
    printf 'failed to install: %s\n' "${failed[@]}" >&2
    exit 1
fi
