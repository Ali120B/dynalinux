# DynaLinux

A compact, OLED-friendly Dynamic Island for Hyprland. Native QML + Quickshell — no Electron, no webview, no CSS.

Based on [Dynamic Glacier](https://github.com/mavxa/DynamicGlacier) by [mavxa](https://github.com/mavxa).

**Owner:** [Ali120B](https://github.com/Ali120B) · alibashmail2010@yahoo.com

---

## Features

- **Idle handle** — small pure-black bump (or a thin strip) at the top center
- **Expand on hover or click** — clock + date, battery, and settings
- **Media player** — album art, track info, scrubber, shuffle / skip / play / like when MPRIS is active
- **Timer** — right-click opens hours/minutes + Start/Reset; progress wraps the island edge
- **Volume & brightness** — the handle morphs into a short level pill (no second OSD)
- **Settings** — small mode (strip) and optional clock in idle
- **end-4 friendly** — no notification daemon, no fighting your existing shell

## Install

### AppImage (easiest while AUR is closed)

1. Download `DynaLinux-x86_64.AppImage` from the [latest release](https://github.com/Ali120B/dynalinux/releases)
2. Make it executable and run:

```sh
chmod +x DynaLinux-x86_64.AppImage
./DynaLinux-x86_64.AppImage
```

The AppImage needs **Quickshell** on the system (`quickshell` in `PATH`). On Arch:

```sh
paru -S quickshell-git
# or: yay -S quickshell
```

### Manual

```sh
git clone https://github.com/Ali120B/dynalinux.git
cd dynalinux
bash install.sh
dynalinux
```

Useful flags: `--symlink`, `--skip-deps`, `--no-autostart`, `--doctor`.

### Hyprland autostart

```ini
exec-once = dynalinux
```

Or, for the AppImage:

```ini
exec-once = /path/to/DynaLinux-x86_64.AppImage
```

### Uninstall

```sh
bash uninstall.sh
```

## Usage

| Action | Result |
|--------|--------|
| Hover / click the handle | Expand |
| Gear icon | Settings |
| Right-click island | Timer |
| Left / right click hour or minute chips | ±1 |
| Media playing | Expanded player with controls |

## Run from the repo

```sh
quickshell --path quickshell
```

IPC target is `dynalinux`:

```sh
quickshell ipc --path quickshell call dynalinux idle
quickshell ipc --path quickshell call dynalinux toggleHandle
quickshell ipc --path quickshell call dynalinux notify "Done" "Build finished" "DynaLinux"
quickshell ipc --path quickshell call dynalinux volume 72 false
```

## Requirements

- Hyprland (Wayland)
- [Quickshell](https://quickshell.outfoxxed.me/)
- Noto Sans
- Material Symbols Rounded (for media icons)
- Optional: `playerctl`, `upower`, PipeWire

## License

MIT. Maintained by **Ali120B**. Original Dynamic Glacier work by **mavxa**.
