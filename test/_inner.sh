#!/usr/bin/env bash
# Runs inside the container. Runs each named script, continuing past failures.
set -uo pipefail

TIMEOUT="${TIMEOUT:-1800}"
REPO=/repo

# A script fails if it touches these; they belong to the dotfiles repo.
guarded=(
    "${HOME}/.bashrc"
    "${HOME}/.bash_profile"
    "${HOME}/.bash_login"
    "${HOME}/.bash_aliases"
    "${HOME}/.profile"
)

# Prints one "path checksum-or-absent" line per guarded file.
snapshot_startup_files() {
    local f
    for f in "${guarded[@]}"; do
        if [[ -e "$f" ]]; then
            echo "$f $(md5sum <"$f" | cut -d" " -f1)"
        else
            echo "$f absent"
        fi
    done
}

declare -a failed=()
declare -a passed=()

# Finds a bare script name in install/, then at the repo root.
resolve() {
    local name="$1" dir
    for dir in "${REPO}/install" "${REPO}"; do
        if [[ -f "${dir}/${name}" ]]; then
            echo "${dir}/${name}"
            return 0
        fi
    done
    return 1
}

for script in "$@"; do
    if ! path=$(resolve "$script"); then
        echo "::: ${script} — no such file" >&2
        failed+=("${script} (missing)")
        continue
    fi

    echo
    echo "::: ${script}"
    echo "::: -------------------------------------------------------------"
    start=$SECONDS
    before=$(snapshot_startup_files)

    # stdin from /dev/null, so a prompt fails instead of hanging.
    timeout --foreground "$TIMEOUT" bash "$path" </dev/null
    status=$?

    elapsed=$((SECONDS - start))

    touched=$(diff <(echo "$before") <(snapshot_startup_files) | awk '/^>/ { print ":::   " $2 }')
    if [[ -n "$touched" ]]; then
        echo "::: ${script} MODIFIED shell startup files (exit ${status}):" >&2
        echo "$touched" >&2
        failed+=("${script} (touched startup files)")
        continue
    fi

    if [[ $status -eq 0 ]]; then
        echo "::: ${script} ok (${elapsed}s)"
        passed+=("$script")
    elif [[ $status -eq 124 ]]; then
        echo "::: ${script} TIMED OUT after ${TIMEOUT}s" >&2
        failed+=("${script} (timeout)")
    else
        echo "::: ${script} FAILED with exit ${status} (${elapsed}s)" >&2
        failed+=("${script} (exit ${status})")
    fi
done

echo
echo "::: ============================================================="
echo "::: passed: ${#passed[@]}   failed: ${#failed[@]}"
for f in "${failed[@]}"; do
    echo ":::   FAIL ${f}"
done

[[ ${#failed[@]} -eq 0 ]]
