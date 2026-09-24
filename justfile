# Every script test-all runs: bootstrap.sh plus install/*.sh except lib.sh.
testable := "bootstrap.sh " + `ls install/*.sh | xargs -n1 basename | grep -v '^lib\.sh$' | tr '\n' ' '`

_default:
    @just --list

# ---- install ------------------------------------------------------------- #

# Bare machine: install git/just/stow and clone the dotfiles
bootstrap:
    bash bootstrap.sh

# Every install script, apt.sh first. Re-running also upgrades
install:
    bash install/apt.sh        # packages/apt.txt, then dist-upgrade. Takes minutes
    bash install/alacritty.sh  # alacritty from apt, registered as x-terminal-emulator
    bash install/gh.sh         # latest GitHub CLI release tarball into ~/.local/opt
    bash install/quarto.sh     # latest Quarto .deb
    bash install/obsidian.sh   # latest Obsidian .deb
    bash install/julia.sh      # juliaup and the current Julia release
    bash install/browser.sh    # Brave, via Brave's own installer
    bash install/syncthing.sh  # syncthing from apt, enabled as a user service
    bash install/neovim.sh     # latest neovim release tarball into ~/.local/opt
    bash install/python.sh     # uv, plus uv tools (papis, ruff, ...)
    bash install/cargo.sh      # the crates in packages/cargo.txt
    #bash install/mermaid.sh    # mmdc, a wrapper around the mermaid-cli container

# ---- test ---------------------------------------------------------------- #

# Run named scripts in a throwaway Ubuntu container, e.g. `just test apt.sh`
test *scripts:
    bash test/run.sh {{scripts}}

# Run every script in a container. ~20 minutes; mermaid.sh always fails here
test-all:
    bash test/run.sh {{testable}}

# Shellcheck, secrets, whitespace. Seconds
check:
    pre-commit run --all-files
