#!/bin/bash
set -euo pipefail

# https://github.com/JuliaLang/juliaup
# --add-to-path no: the dotfiles own ~/.bashrc and PATH.
curl -fsSL https://install.julialang.org | sh -s -- -y --add-to-path no

"${HOME}/.juliaup/bin/juliaup" update
