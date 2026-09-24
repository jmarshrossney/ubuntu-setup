# Ubuntu setup

Install scripts for a fresh Ubuntu 26.04 machine.
Dotfiles live separately in `~/github.com/jmarshrossney/dotfiles`.

| Path | Contents |
|---|---|
| `bootstrap.sh` | first thing to run on a bare machine |
| `justfile` | entry point for everything else |
| `install/` | one script per tool, plus shared functions in `lib.sh` |
| `packages/` | apt and cargo package lists |
| `test/` | container tests, see `test/README.md` |
| `README.desktop.md` | manual steps for the desktop: NVIDIA, SSH server, backup HDD |

## Fresh machine

1. Bootstrap. This installs git, just and stow, and clones the dotfiles.

   ```sh
   sudo apt-get install -y git
   git clone https://github.com/jmarshrossney/ubuntu-setup.git
   bash ubuntu-setup/bootstrap.sh
   ```

2. Link the dotfiles by following the instructions `bootstrap.sh` prints.

3. Install everything:

   ```sh
   just install
   ```

4. Finish by hand:
   - **Desktop:** follow `README.desktop.md`.
   - **Nerd Fonts:** see the `alacritty` package README in the dotfiles repo.
   - **Default terminal:** `sudo update-alternatives --config x-terminal-emulator` and pick alacritty.
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
