#!/usr/bin/env bash
# Run setup scripts against a throwaway Ubuntu container.
#
#   bash test/run.sh apt.sh python.sh      run those, report per-script status
#   bash test/run.sh --shell               drop into a shell in the test image
#   UBUNTU=24.04 bash test/run.sh apt.sh   test against an older Ubuntu release
set -euo pipefail

UBUNTU="${UBUNTU:-26.04}"
TIMEOUT="${TIMEOUT:-1800}"
IMAGE="ubuntu-setup-test:${UBUNTU}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

shell_mode=0
rebuild=0
scripts=()

for arg in "$@"; do
    case "$arg" in
        --shell)   shell_mode=1 ;;
        --rebuild) rebuild=1 ;;
        # Print the header comment.
        -h|--help) awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next }
                        NR>1 { exit }' "${BASH_SOURCE[0]}"; exit 0 ;;
        -*)        echo "unknown option: $arg" >&2; exit 2 ;;
        *)         scripts+=("$arg") ;;
    esac
done

if ! command -v podman >/dev/null 2>&1; then
    echo "podman not found; install it with: sudo apt-get install podman" >&2
    exit 1
fi

# Podman before 4.7 has a seccomp profile that returns EPERM for fchmodat2,
# which breaks extracting tarballs containing symlinks.
podman_version=$(podman --version | sed -n 's/^podman version \([0-9]*\.[0-9]*\).*/\1/p')
if [[ -n "$podman_version" ]] \
    && (( ${podman_version%.*} < 4 || (${podman_version%.*} == 4 && ${podman_version#*.} < 7) )); then
    echo "::: warning: podman ${podman_version} is old enough that tar archives" >&2
    echo "::: containing symlinks fail to extract. See test/README.md." >&2
fi

build_args=(--build-arg "UBUNTU=${UBUNTU}" -t "$IMAGE" -f "${REPO_ROOT}/test/Containerfile")
[[ $rebuild -eq 1 ]] && build_args+=(--no-cache)

echo "::: building ${IMAGE}"
build_log=$(mktemp)
trap 'rm -f "$build_log"' EXIT
if ! podman build "${build_args[@]}" "${REPO_ROOT}/test" >"$build_log" 2>&1; then
    cat "$build_log" >&2
    echo "::: image build failed" >&2
    exit 1
fi

# No --userns=keep-id: with it, sudo in the container lacks real root in the
# namespace and tar cannot restore file modes.
run_args=(--rm -v "${REPO_ROOT}:/repo:ro" -e "TIMEOUT=${TIMEOUT}")

if [[ $shell_mode -eq 1 ]]; then
    exec podman run -it "${run_args[@]}" "$IMAGE" bash
fi

if [[ ${#scripts[@]} -eq 0 ]]; then
    echo "nothing to run; pass script names or --shell" >&2
    exit 2
fi

exec podman run "${run_args[@]}" "$IMAGE" bash /repo/test/_inner.sh "${scripts[@]}"
