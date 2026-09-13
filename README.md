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
| `packages/optional/` | Ignored by the installer. Create it and park a list there to disable it. |
| `dotfiles/` | Mirrors `$HOME`. Contents get symlinked in. |
| `services/*.txt` | systemd units to `enable --now`. |
| `lib/common.sh` | Logging and shared helpers. |

## Adding an app

Put its name in the right file under `packages/`. That's the whole workflow —
no code changes. Repo packages go in any `*.txt`; AUR packages go in `aur.txt`.

The lists deliberately contain **only what CachyOS does not already give you**,
derived from the installer's `netinstall.yaml` and the live ISO package list
plus their full dependency closures. Don't re-add stock packages — a fresh
install already has them.

To find what you've installed since the last sync:

```sh
comm -23 <(pacman -Qqe | sort -u) \
         <(cat packages/*.txt \
           | sed -e 's/#.*//' | tr -d ' ' | grep -v '^$' | sort -u)
```

Cross-check a candidate against the stock set before adding it:

```sh
curl -s https://raw.githubusercontent.com/CachyOS/calamares-config/master/etc/calamares/modules/netinstall.yaml \
  | grep -qx '      - PKGNAME' && echo 'ships by default, skip it'
```

## Adding dotfiles

Drop the file into `dotfiles/` at the path it should have under `$HOME`:

```
dotfiles/.zshrc                        ->  ~/.zshrc
dotfiles/.config/alacritty/foo.toml    ->  ~/.config/alacritty/foo.toml
```

Stage 40 symlinks them. Anything real already in the way is moved to
`~/.dotfiles-backup/<timestamp>/` first, never deleted. `.idea/` directories
are skipped, so JetBrains project files can live alongside a config without
being linked into `$HOME`.

## Stages

| Stage | Does |
|---|---|
| `10-pacman` | Colour, parallel downloads, `ILoveCandy`; full system sync. |
| `20-aur-helper` | Installs `paru` from the AUR if no helper is present. |
| `30-packages` | Installs everything in `packages/`. |
| `40-dotfiles` | Symlinks `dotfiles/` into `$HOME`. |
| `50-services` | Enables the units in `services/`. |
| `60-kde-shortcuts` | Re-binds KDE global shortcuts for the `~/.bin` scripts. |

Add a stage by dropping a numbered script into `scripts/`. It gets picked up
automatically; source `lib/common.sh` at the top for the helpers.

## Audio switching

`dotfiles/.bin/` carries two scripts, and the setup reproduces everything they
need to actually run:

| File | Purpose |
|---|---|
| `.bin/switchAudio.sh` | Toggles the default sink between the Focusrite Scarlett Solo and the SteelSeries Arctis Nova Pro, loading the matching EasyEffects preset. |
| `.bin/setAudioLevels.sh` | Sets the Scarlett as default and nudges its volume. Runs at login. |
| `.local/share/easyeffects/output/{Eris3-5,NovaPro}.json` | The presets `switchAudio.sh` loads. Without these it switches sinks but the EQ silently fails. |
| `.config/autostart/setAudioLevels.sh.desktop` | Runs `setAudioLevels.sh` at login. |
| `.local/share/applications/net.local.switchAudio.sh.desktop` | Hidden launcher that exists purely to give the shortcut something to bind to. |

The key binding itself (`Launch (5)`) lives in `kglobalshortcutsrc` next to every
other KDE shortcut, so it can't be symlinked without clobbering the rest —
stage 60 sets just that one key with `kwriteconfig6`.

`easyeffects` is listed in `packages/media.txt` even though CachyOS ships it,
because `switchAudio.sh` breaks without it and the distro's default set is not a
promise.

## Hyprland

The Lua config is in `dotfiles/.config/hypr/` and gets linked to
`~/.config/hypr/` like any other dotfile. `packages/hyprland.txt` holds the
compositor plus everything the config launches that isn't already listed
elsewhere:

| Package | Used by |
|---|---|
| `hyprland`, `xdg-desktop-portal-hyprland` | The session itself; the portal handles screen sharing. |
| `noctalia` | Bar, launcher, notifications, window switcher. Started in `autostart.lua`, driven by `SUPER+Space`, `SUPER+,`, `ALT+Tab`. |
| `awww` | Wallpaper daemon, started in `autostart.lua`. |
| `hyprlauncher` | The `launcher` variable in `keybinds.lua`. |
| `playerctl` | Media keys. |
| `rose-pine-hyprcursor` (AUR) | `HYPRCURSOR_THEME`. |

Everything else it calls — `alacritty`, `dolphin`, `easyeffects`, `protonvpn`,
`zen-browser`, `spotify-launcher`, `steam`, `webstorm` — is either stock or
already in another list.

Pick Hyprland from the session menu at the SDDM login screen.

## Notes

- `monitors.lua` names outputs `DP-1`/`DP-2`/`DP-3` with this desk's layout.
  On other hardware, get the names from `hyprctl monitors` and fix it, or
  Hyprland will fall back to auto-placing everything.

- `gaming.txt` assumes AMD (`lib32-vulkan-radeon`). Swap for
  `lib32-nvidia-utils` on NVIDIA.
- The two `.desktop` files hardcode `/home/sam/.bin/...`. If the username on the
  new machine differs, fix those two `Exec=` lines.
- `~/.bin` is not on `$PATH`. Nothing needs it to be — both scripts are launched
  by absolute path — but you can't type their names in a shell as-is.
- The sink names in both scripts are specific to that Focusrite and SteelSeries
  hardware. On different gear, get the new names from `pactl list short sinks`.
- KDE only reloads shortcuts on login, so stage 60's binding needs a re-login.
- Virtualisation needs a manual step the scripts don't do for you:
  `sudo usermod -aG libvirt $USER`, then log out and back in.
