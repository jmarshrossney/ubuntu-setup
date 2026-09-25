# Ubuntu setup

Install scripts for a fresh Ubuntu 26.04 machine.
Dotfiles live separately in `~/github.com/jmarshrossney/dotfiles`.

| Path | Contents |
|---|---|
| `bootstrap.sh` | first thing to run on a bare machine; runs everything else |
| `justfile` | entry point for everything else |
| `install/` | one script per tool, plus shared functions in `lib.sh` |
| `packages/` | apt and cargo package lists |
| `test/` | container tests, see `test/README.md` |
| `README.desktop.md` | manual steps for the desktop: NVIDIA, SSH server, backup HDD |

## Fresh machine

1. Bootstrap.
   This installs git, just and stow, clones the dotfiles and links them all, loads the GNOME settings, then runs `just install`.

   ```sh
   sudo apt-get install -y git
   git clone https://github.com/jmarshrossney/ubuntu-setup.git ~/github.com/jmarshrossney/ubuntu-setup
   bash ~/github.com/jmarshrossney/ubuntu-setup/bootstrap.sh
   ```

   Files in the way of the dotfiles, such as Ubuntu's `~/.bashrc`, are moved to `~/.dotfiles-backup/<timestamp>/`.

2. Log out and back in, so the session picks up the new shell config, fonts and default terminal.

3. Finish by hand:
   - **Desktop:** follow `README.desktop.md`.
   - **Syncthing:** pair each device at http://127.0.0.1:8384.
     If the script could not start the service, run `systemctl --user enable --now syncthing.service`.

## Day to day

```sh
just install              # re-run everything; re-running also upgrades
bash install/neovim.sh    # re-run one script
```

To add a package, put its name in `packages/apt.txt` or `packages/cargo.txt` (one per line, `#` for comments), then run `bash install/apt.sh` or `bash install/cargo.sh`.
`apt.sh` installs every valid name and then lists any that have no installation candidate.

To pin a version, pass it to the script:

| Script | Example |
|---|---|
| `install/gh.sh` | `bash install/gh.sh 2.86.0` |
| `install/neovim.sh` | `bash install/neovim.sh v0.11.6` |
| `install/quarto.sh` | `bash install/quarto.sh 1.10.18` |

`mmdc` runs mermaid-cli in a container that sees only the current directory, so give it relative paths.
Update it with `podman pull ghcr.io/mermaid-js/mermaid-cli/mermaid-cli`.

## Developer setup

```sh
pre-commit install  # run the checks on every commit
just check          # shellcheck, secrets, whitespace; seconds
just test-all       # every script in a fresh container, ~20 minutes
```

`pre-commit` comes from `install/python.sh`; testing needs rootless podman.

Details in `test/README.md`.
