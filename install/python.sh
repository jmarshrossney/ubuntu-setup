#!/bin/bash
set -euo pipefail

# uv, then global Python tools. uv fetches interpreters on demand.
# https://docs.astral.sh/uv/getting-started/installation/
# UV_NO_MODIFY_PATH: the dotfiles own ~/.bashrc and PATH.
curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh

UV="${HOME}/.local/bin/uv"
"$UV" --version

# Each tool gets its own environment. For neovim's python3 provider, point
# g:python3_host_prog at ~/.local/bin/pynvim-python.
for tool in papis pre-commit pylatexenc pynvim ruff; do
    "$UV" tool install --upgrade "$tool"
done
