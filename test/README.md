# Testing

Needs rootless podman.

```sh
just check                     # shellcheck, secrets, whitespace; seconds
just test apt.sh python.sh     # run named scripts in a fresh container
just test-all                  # run every script, ~20 minutes
bash test/run.sh --shell       # interactive shell in the test image, to debug a failing script
UBUNTU=24.04 just test apt.sh  # test another release (26.04 by default)
TIMEOUT=600 just test apt.sh   # per-script timeout in seconds (default 1800)
```

`test-all` picks up every script in `install/` automatically.

## In the container

- The repo is mounted read-only at `/repo`.
- Scripts run as a normal user with passwordless sudo.
- Stdin is `/dev/null`, so a script that prompts fails instead of hanging.
- A script fails if it modifies `~/.bashrc`, `~/.bash_profile`, `~/.bash_login`, `~/.bash_aliases` or `~/.profile`.
  Those belong to the dotfiles repo.
  Upstream installers need telling: `UV_NO_MODIFY_PATH=1` for uv, `--add-to-path no` for juliaup, `--no-modify-path` for rustup.

## Expected failures

- **`mermaid.sh` fails in `test-all`** at `podman pull`, because that is podman inside podman.
  A clean run is therefore 11 passed, 1 failed.
  It passes when run on its own, because podman is not installed yet.
- **Podman older than 4.7** cannot extract tarballs containing symlinks (`Cannot change mode ... Operation not permitted`), which breaks `gh.sh` and `neovim.sh`.
  `test/run.sh` warns about this.
  The scripts are fine; upgrade podman.
- **`README.desktop.md`** is untested here: the NVIDIA driver needs real hardware and a reboot.
