# DynaLinux

A compact, OLED-friendly island for Hyprland. Native QML + Quickshell — no Electron, no webview.

Based on [Dynamic Glacier](https://github.com/mavxa/DynamicGlacier) by [mavxa](https://github.com/mavxa).

**Owner:** [Ali120B](https://github.com/Ali120B) · alibashmail2010@yahoo.com

## What it does

- Idle handle at the top center (`bump` or a thin `strip`)
- Hover shows time and weather
- Click expands: clock + date, or a media player when something is playing
- Settings: small mode, clock in idle
- Right-click opens a timer (hours / minutes, Start, Reset). A ring and an edge line show progress
- Volume and brightness morph the handle into a short level pill

## Install

**Manual**

```sh
git clone https://github.com/Ali120B/dynalinux.git
cd dynalinux
bash install.sh
dynalinux
```

Useful flags: `--symlink`, `--skip-deps`, `--no-autostart`, `--doctor`.

**Arch (AUR, after you publish it)**

```sh
paru -S dynalinux-git
dynalinux
```

Uninstall a manual install with `bash uninstall.sh`.

## Run from the repo

```sh
quickshell --path quickshell
```

## License

MIT. DynaLinux is maintained by Ali120B. The original Dynamic Glacier work is by mavxa.
