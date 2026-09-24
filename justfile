# Every script test-all runs: bootstrap.sh plus install/*.sh except lib.sh.
testable := "bootstrap.sh " + `ls install/*.sh | xargs -n1 basename | grep -v '^lib\.sh$' | tr '\n' ' '`

_default:
    @just --list

# ---- install ------------------------------------------------------------- #
#
# `: apt` means the recipe needs something apt.sh installs.

# Bare machine: install git/just/stow and clone the dotfiles
bootstrap:
    bash bootstrap.sh

# Everything, quick installs first
all: alacritty gh quarto obsidian julia browser syncthing apt neovim mermaid python cargo

# Every package in packages/apt.txt, then dist-upgrade. Takes minutes
apt:
    bash install/apt.sh

# uv, plus papis, pre-commit, pylatexenc, pynvim and ruff as uv tools
python: apt
    bash install/python.sh

# Latest neovim release tarball into ~/.local/opt
neovim:
    bash install/neovim.sh

# The crates in packages/cargo.txt, built with cargo
cargo: apt
    bash install/cargo.sh

# Alacritty from apt, registered as x-terminal-emulator
alacritty:
    bash install/alacritty.sh

# Brave, via Brave's own installer
browser:
    bash install/browser.sh

# Latest GitHub CLI release tarball into ~/.local/opt
gh:
    bash install/gh.sh

# mmdc, a wrapper around the mermaid-cli container
mermaid: apt
    bash install/mermaid.sh

# juliaup and the current Julia release
julia:
    bash install/julia.sh

# Latest Obsidian .deb
obsidian:
    bash install/obsidian.sh

# Latest Quarto .deb
quarto:
    bash install/quarto.sh

# Syncthing from apt, enabled as a user service
syncthing:
    bash install/syncthing.sh

# ---- test ---------------------------------------------------------------- #

# Run named scripts in a throwaway Ubuntu container, e.g. `just test apt.sh`
test *scripts:
    bash test/run.sh {{scripts}}

# Run every script in a container. ~20 minutes; mermaid.sh always fails here
test-all:
    bash test/run.sh {{testable}}

# Interactive shell in the test image
shell:
    bash test/run.sh --shell

# Shellcheck, secrets, whitespace. Seconds
check:
    pre-commit run --all-files

# Install the pre-commit hook, so `check` also runs on every commit
install-hooks:
    pre-commit install
