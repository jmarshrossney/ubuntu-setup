# Desktop setup

Manual steps for the desktop only, after `bootstrap.sh` and `just install`.

## NVIDIA driver

### Why 580

- The card is a GTX 1060 (Pascal, compute capability 6.1).
- 580 is NVIDIA's last driver branch for Maxwell, Pascal and Volta.
  595 and 610 have dropped them.
- The `-open` kernel modules need Turing or newer, so use the proprietary ones.
- On 26.04 only `nvidia-driver-580` and `-580-server` list this card's PCI ID, so `ubuntu-drivers autoinstall` should pick 580.
  On 22.04 it picked 390 for the same card, so do not trust it blindly.
- A new card means rechecking all of this.

### Install

```sh
sudo apt-get update
sudo apt-get remove -y 'linux-modules-nvidia-580-*'
sudo apt-get install -y nvidia-driver-580
dkms status
```

Why the `remove`:

- `ubuntu-drivers`, and the installer's "third-party drivers" box, add Canonical's prebuilt `linux-modules-nvidia-*` packages.
- Those exist only for kernels Canonical has built them for, and a kernel update can land before its matching modules do.
- The DKMS module that `nvidia-driver-580` pulls in is built locally for every installed kernel, so use that instead.
- Removing the prebuilt packages first stops them causing the DKMS build to be skipped.
- On a machine that never had them, the `remove` does nothing.

`dkms status` should show `nvidia/580.x, <kernel>, x86_64: installed` for the running kernel.
If it does not, `nvidia-dkms` was already installed and did not rebuild:

```sh
sudo apt-get install --reinstall nvidia-dkms-580
```

### Secure Boot

With Secure Boot on, the install asks for a one-off password to sign the module with a machine owner key.
The next boot stops at a blue MokManager screen asking for that password again to enroll the key.
**Skip the enrollment and the driver will not load.**

### Check after reboot

```sh
nvidia-smi
cat /sys/module/nvidia_drm/parameters/modeset    # expect Y
```

Wayland needs DRM modesetting, and 26.04 has no X11 session to fall back to, so `N` means no desktop at all.
The driver has defaulted it on since 545, but if it ever reads `N`:

```sh
echo 'options nvidia-drm modeset=1' | sudo tee /etc/modprobe.d/nvidia-drm.conf
sudo update-initramfs -u && sudo reboot
```

### CUDA for JAX and PyTorch

Nothing else to install system-wide.
The driver provides `libcuda`, which every CUDA program uses to talk to the GPU.
JAX and PyTorch fetch the rest of CUDA as pip packages, per project.

**CUDA 13 dropped Pascal**, so each project must ask for CUDA 12 builds explicitly (checked 2026-09-24).

**JAX** supports SM 5.2 and newer on CUDA 12, with driver 525 or newer:

```sh
uv add 'jax[cuda12]'
```

`jax[cuda13]` installs but will not run on this card.

**PyTorch**'s default PyPI wheels are CUDA 13 builds.
Point uv at the CUDA 12.6 index instead, which is built for SM 5.0, 6.0, 7.0 and newer (6.0 code runs on this 6.1 card).
In the project's `pyproject.toml`:

```toml
[[tool.uv.index]]
name = "pytorch-cu126"
url = "https://download.pytorch.org/whl/cu126"
explicit = true

[tool.uv.sources]
torch = { index = "pytorch-cu126" }
```

Then `uv add torch`.
If the project uses `torchvision`, add it to `[tool.uv.sources]` the same way.

**Check:**

```sh
uv run python -c 'import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name())'
uv run python -c 'import jax; print(jax.devices())'
```

**Pin versions** in any project that needs to keep working.
Both JAX and PyTorch will drop CUDA 12 eventually, and after that this card is stuck on the last release that has it.

**Do not install NVIDIA's CUDA toolkit from its apt repository.**
The `ubuntu2604` repository has only CUDA 13, and the unversioned `cuda-toolkit` or `cuda-drivers` packages replace the driver above.

## SSH server, home network only

End state: key-only login as `<user>`, from `192.168.1.0/24` only, firewalled to the LAN, with no port forward on the router.
Passwords stay on until every laptop's key is copied across (step 5), then go off (step 6).
`<user>` is your login name on the desktop and `<desktop-ip>` is the address reserved in step 1.

### 1. Fixed address

On the router:

- Give the desktop a DHCP reservation. This is `<desktop-ip>`.
- Check there is no port forward to the desktop.
- Check the IPv6 firewall blocks unsolicited incoming connections.

### 2. Firewall

```sh
sudo ufw default deny incoming
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp
sudo ufw allow from 192.168.1.0/24 to any app syncthing
sudo ufw enable
sudo ufw status verbose
```

Without the Syncthing rule, Syncthing between machines in the house falls back to its slower relays.

### 3. Configure sshd

Permanent config:

```sh
sudo mkdir -p /etc/ssh/sshd_config.d
sudo tee /etc/ssh/sshd_config.d/10-lan-keys-only.conf <<'EOF'
# Keys only
PasswordAuthentication no
KbdInteractiveAuthentication no
AuthenticationMethods publickey
PermitRootLogin no

# One user, from the home network only
AllowUsers <user>@192.168.1.0/24

# ssh and sshfs need none of these
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
EOF
```

Temporary config, allowing passwords until step 6:

```sh
sudo tee /etc/ssh/sshd_config.d/05-setup-passwords.conf <<'EOF'
# Temporary: delete once every laptop's key is installed
PasswordAuthentication yes
AuthenticationMethods any
EOF
```

sshd reads the files in name order and keeps the first value it sees, so `05-` overrides `10-`, and `10-` overrides the stock `sshd_config`.

### 4. Install and check

```sh
sudo apt-get install -y openssh-server
sudo sshd -t && echo ok
```

### 5. On each laptop

Make a key for the desktop:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_desktop -C "$(hostname) to desktop"
```

Add to `~/.ssh/config`:

```
Host desktop
    HostName <desktop-ip>
    User <user>
    IdentityFile ~/.ssh/id_ed25519_desktop
    IdentitiesOnly yes
```

Copy the key across (enter the desktop password once), then check the key works on its own:

```sh
ssh-copy-id -i ~/.ssh/id_ed25519_desktop.pub desktop
ssh -o PasswordAuthentication=no desktop true && echo ok
```

### 6. Turn passwords off

Once every laptop passes step 5, at the desktop:

```sh
sudo rm /etc/ssh/sshd_config.d/05-setup-passwords.conf
sudo sshd -t && sudo systemctl restart ssh
sudo sshd -T -C user=<user>,host=laptop,addr=192.168.1.50 \
  | grep -E '^(passwordauthentication|authenticationmethods|allowusers) '
```

Expect `passwordauthentication no`, `authenticationmethods publickey` and `allowusers <user>@192.168.1.0/24`.
Then, from a laptop:

```sh
ssh desktop true && echo ok
ssh -o PubkeyAuthentication=no desktop    # expect: Permission denied (publickey)
```

### Mounting the backup from a laptop

`<mountpoint>` is the desktop's backup mount point, set in [Automount](#automount).

```sh
mkdir -p ~/mnt/backup
sshfs desktop:<mountpoint>/Backup ~/mnt/backup -o reconnect,ServerAliveInterval=15
fusermount3 -u ~/mnt/backup      # unmount
```

`fusermount3: user has no write access to mountpoint` means the local mount point is not owned by your user, e.g. it was made with `sudo` or is under `/mnt`.

### Later

- **New laptop:** recreate `05-setup-passwords.conf`, restart ssh, then do steps 5 and 6.
  Or append its `.pub` to `~/.ssh/authorized_keys` on the desktop by hand.
- **Config change:** `sudo sshd -t && sudo systemctl restart ssh`.
  Do it at the desktop, or keep one SSH session open while testing, so a mistake cannot lock you out.
- **Access from outside the house:** use a VPN such as Tailscale or WireGuard, and add its addresses to `AllowUsers` and ufw.

## Backup HDD: automount and spin-down

The internal HDD has one ext4 partition.

### Find the drive

```sh
lsblk -e7 -o NAME,SIZE,ROTA,MODEL,FSTYPE,UUID,WWN,MOUNTPOINTS
```

The HDD is the disk with `ROTA` 1 and the right size and model.
Note:

| Placeholder | Column | Row | Used in |
|---|---|---|---|
| `<uuid>` | `UUID` | the partition, e.g. `sda1` | `/etc/fstab` |
| `<wwn>` | `WWN` | the disk, e.g. `sda` | `/etc/hdparm.conf`, `hdparm` |

`ls -l /dev/disk/by-id/wwn-<wwn>` should point at the disk, not a partition.

### Automount

Pick a `<mountpoint>` named for its purpose, e.g. `/srv/backup`, so replacing the drive only changes `<uuid>` and `<wwn>`.

Add to `/etc/fstab`, to mount on first access and unmount after 10 idle minutes:

```
UUID=<uuid>  <mountpoint>  ext4  noauto,nofail,noatime,x-systemd.automount,x-systemd.idle-timeout=10min  0  2
```

```sh
sudo findmnt --verify
sudo umount <mountpoint>                # if it is currently mounted
sudo systemctl daemon-reload
sudo systemctl start "$(systemd-escape --path --suffix=automount <mountpoint>)"
```

**Mirror scripts must check for a path that is always on the drive, such as `Backup/Archive`.**
With the drive missing, `<mountpoint>` is an empty directory, and `rsync --delete` would empty the mirrors to match.
`mountpoint -q` does not help, because the automount point counts as a mount.

### Spin-down

Add to `/etc/hdparm.conf` (read at boot):

```
/dev/disk/by-id/wwn-<wwn> {
    spindown_time = 241
}
```

`241` is 30 minutes.
Values 1-240 count in 5-second steps; 241-251 count in 30-minute steps.

To apply now and check the state:

```sh
sudo hdparm -S 241 /dev/disk/by-id/wwn-<wwn>
sudo hdparm -C /dev/disk/by-id/wwn-<wwn>    # active/idle or standby
```
