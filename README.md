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
   just all
   ```

4. Finish by hand:
   - **Desktop:** follow `README.desktop.md`.
   - **Nerd Fonts:** see the `alacritty` package README in the dotfiles repo.
   - **Default terminal:** `sudo update-alternatives --config x-terminal-emulator` and pick alacritty.
   - **Syncthing:** pair each device at http://127.0.0.1:8384.
     If the script could not start the service, run `systemctl --user enable --now syncthing.service`.

## Day to day

```sh
just              # list recipes
just apt          # re-run one script; re-running also upgrades
just all          # re-run everything
```

To add a package, put its name in `packages/apt.txt` or `packages/cargo.txt` (one per line, `#` for comments), then run `just apt` or `just cargo`.
`apt.sh` installs every valid name and then lists any that have no installation candidate.

To pin a version, pass it to the script:

| Script | Example |
|---|---|
| `install/gh.sh` | `bash install/gh.sh 2.86.0` |
| `install/neovim.sh` | `bash install/neovim.sh v0.11.6` |
| `install/quarto.sh` | `bash install/quarto.sh 1.10.18` |

`mmdc` runs mermaid-cli in a container that sees only the current directory, so give it relative paths.
Update it with `podman pull ghcr.io/mermaid-js/mermaid-cli/mermaid-cli`.

## Testing

```sh
just check        # shellcheck and pre-commit hooks, seconds
just test-all     # every script in a fresh container, ~20 minutes
```

Details in `test/README.md`.
