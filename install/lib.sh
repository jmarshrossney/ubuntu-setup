# Sourced by the install scripts, not run directly.
# shellcheck shell=bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# Prints the package names in packages/<list>.txt, dropping comments and blanks.
package_list() {
    local file="${REPO_ROOT}/packages/${1}.txt"
    if [[ ! -f "$file" ]]; then
        echo "no such package list: ${file}" >&2
        return 1
    fi
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$file" | grep -v '^[[:space:]]*$'
}

# apt_install <list> [extra apt-get flags...]
#
# Installs every name in packages/<list>.txt that has an installation
# candidate, then lists the ones that do not and returns 1.
#
# Caveat: a purely virtual package is reported as having no candidate.
apt_install() {
    local list="$1"
    shift

    local -a wanted=() available=() missing=()
    mapfile -t wanted < <(package_list "$list")

    sudo apt-get update -qq

    local pkg candidate
    for pkg in "${wanted[@]}"; do
        candidate=$(apt-cache policy "$pkg" 2>/dev/null \
            | awk '/^  Candidate:/ { print $2 }')
        if [[ -n "$candidate" && "$candidate" != "(none)" ]]; then
            available+=("$pkg")
        else
            missing+=("$pkg")
        fi
    done

    if (( ${#available[@]} > 0 )); then
        sudo apt-get install -qy "$@" "${available[@]}"
    fi

    if (( ${#missing[@]} > 0 )); then
        echo >&2
        printf 'no installation candidate: %s\n' "${missing[@]}" >&2
        echo "fix packages/${list}.txt; the other ${#available[@]} packages installed fine" >&2
        return 1
    fi
}

# latest_github_tag <owner/repo>
#
# Prints the latest release tag with any leading "v" removed.
# Not `grep -m1`: it closes the pipe early and pipefail fails on curl's SIGPIPE.
latest_github_tag() {
    local json
    json=$(curl -fsSL "https://api.github.com/repos/${1}/releases/latest")
    awk -F'"' '/"tag_name"/ && !v { v = $4 } END { sub(/^v/, "", v); print v }' <<<"$json"
}

# install_release_tarball <url> <dir> <bin-relpath> <prune-glob>
#
# Unpacks a release tarball under ~/.local/opt and symlinks one binary from it
# into ~/.local/bin. <dir> is the directory the tarball unpacks to;
# <prune-glob> matches other versions of it, which are removed.
install_release_tarball() {
    local url="$1" dir="$2" bin="$3" prune="$4"
    local opt="${HOME}/.local/opt" bindir="${HOME}/.local/bin"

    local tmp
    tmp=$(mktemp -d)
    # shellcheck disable=SC2064  # $tmp is expanded now on purpose
    trap "rm -rf '$tmp'" RETURN

    echo "Fetching ${url}"
    curl -fsSL "$url" -o "${tmp}/tarball.tar.gz"

    mkdir -p "$opt" "$bindir"
    rm -rf "${opt:?}/${dir}"
    tar -C "$opt" -xzf "${tmp}/tarball.tar.gz"
    ln -sfn "${opt}/${dir}/${bin}" "${bindir}/$(basename "$bin")"

    find "$opt" -maxdepth 1 -name "$prune" ! -name "$dir" -exec rm -rf {} +
}
