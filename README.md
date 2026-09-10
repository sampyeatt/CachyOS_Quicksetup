# automatic-setup

Rebuild my machine after a fresh Arch/CachyOS install.

## Use it

```sh
git clone <this-repo> ~/Projects/automatic-setup
cd ~/Projects/automatic-setup
./install.sh --dry-run   # see what it would do
./install.sh             # do it
```

Re-running is safe. Every stage is idempotent, so this doubles as "sync this
machine back up to what the repo says it should be".

```sh
./install.sh --list        # show stages
./install.sh packages      # run one stage
./install.sh 30 50         # run several
```

## Layout

| Path | What it is |
|---|---|
| `install.sh` | Entry point. Runs the stages in order. |
| `scripts/NN-*.sh` | One stage each. Numbered, run in order. |
| `packages/*.txt` | What to install. One package per line, `#` comments fine. |
| `packages/aur.txt` | Same, but installed via `paru`/`yay`. |
| `packages/optional/` | **Ignored.** Park a list here to disable it. |
| `dotfiles/` | Mirrors `$HOME`. Contents get symlinked in. |
| `services/*.txt` | systemd units to `enable --now`. |
| `lib/common.sh` | Logging and shared helpers. |

## Adding an app

Put its name in the right file under `packages/`. That's the whole workflow —
no code changes. Repo packages go in any `*.txt`; AUR packages go in `aur.txt`.

To find what you've installed since the last sync:

```sh
comm -23 <(pacman -Qqe | sort -u) \
         <(cat packages/*.txt packages/optional/*.txt \
           | sed -e 's/#.*//' | tr -d ' ' | grep -v '^$' | sort -u)
```

## Adding dotfiles

Drop the file into `dotfiles/` at the path it should have under `$HOME`:

```
dotfiles/.zshrc                        ->  ~/.zshrc
dotfiles/.config/alacritty/foo.toml    ->  ~/.config/alacritty/foo.toml
```

Stage 40 symlinks them. Anything real already in the way is moved to
`~/.dotfiles-backup/<timestamp>/` first, never deleted.

## Stages

| Stage | Does |
|---|---|
| `10-pacman` | Colour, parallel downloads, `ILoveCandy`; full system sync. |
| `20-aur-helper` | Installs `paru` from the AUR if no helper is present. |
| `30-packages` | Installs everything in `packages/`. |
| `40-dotfiles` | Symlinks `dotfiles/` into `$HOME`. |
| `50-services` | Enables the units in `services/`. |

Add a stage by dropping a numbered script into `scripts/`. It gets picked up
automatically; source `lib/common.sh` at the top for the helpers.

## Notes

- `packages/optional/distro-defaults.txt` is the kernel/bootloader/firmware/
  filesystem set that the CachyOS installer already gives you. It's a record,
  not something to reinstall.
- `gaming.txt` assumes AMD (`lib32-vulkan-radeon`). Swap for
  `lib32-nvidia-utils` on NVIDIA.
- Virtualisation needs a manual step the scripts don't do for you:
  `sudo usermod -aG libvirt $USER`, then log out and back in.
