# Development

```sh
quickshell --path quickshell
```

IPC target is `dynalinux`:

```sh
quickshell ipc --path quickshell call dynalinux idle
quickshell ipc --path quickshell call dynalinux toggleHandle
quickshell ipc --path quickshell call dynalinux notify "Done" "Build finished" "DynaLinux"
quickshell ipc --path quickshell call dynalinux volume 72 false
quickshell ipc --path quickshell call dynalinux brightness 80
```

Layout:

- `quickshell/shell.qml` — entry
- `quickshell/modules/dynalinux/DynaLinux.qml` — state, services, window
- `IslandSurface.qml` — shape and animation
- `IslandContent.qml` — per-mode UI

Keep new behavior in `DynaLinux.qml`. Do not bind `exclusiveZone` to the expanded height.
