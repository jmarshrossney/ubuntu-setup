#!/bin/bash
set -euo pipefail

# Installs ~/.local/bin/mmdc, a wrapper that runs mermaid-cli in a container.
# https://github.com/mermaid-js/mermaid-cli

IMAGE="ghcr.io/mermaid-js/mermaid-cli/mermaid-cli"
BIN_DIR="${HOME}/.local/bin"

mkdir -p "$BIN_DIR"

# --userns=keep-id with -u runs the container as you, so it can read the bind
# mount and its output files are owned by you.
cat > "${BIN_DIR}/mmdc" <<'WRAPPER'
#!/bin/sh
# mermaid-cli in a container. Installed by ubuntu-setup/mermaid.sh.
# Paths must be relative to the current directory, which is all the container
# can see.
set -eu
exec podman run --rm --userns=keep-id -u "$(id -u):$(id -g)" \
    -v "${PWD}:/data" \
    ghcr.io/mermaid-js/mermaid-cli/mermaid-cli "$@"
WRAPPER
chmod +x "${BIN_DIR}/mmdc"

echo "installed ${BIN_DIR}/mmdc"

# Pull now (~400MB). Re-run `podman pull` to update.
if command -v podman >/dev/null 2>&1; then
    podman pull "$IMAGE"
else
    echo "podman not found; mmdc will not run until install/apt.sh has been" >&2
    echo "and 'podman pull ${IMAGE}' has fetched the image" >&2
fi
