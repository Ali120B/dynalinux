# Architecture

```text
quickshell/shell.qml
  DynaLinux.qml
    PanelWindow
      IslandSurface.qml
        IslandContent.qml
```

One visual mode at a time: `idle`, `hover`, `expanded`, `settings`, `timer`, `notify`, `volume`.

Click the handle to expand. Hovering the idle handle opens the compact time/weather pill. Right-click opens the timer. Settings stays the same size as expand so the pointer does not fall off the island.

Live inputs (non-owning):

- MPRIS for the vinyl and the expanded player
- PipeWire default sink for the volume pill
- sysfs backlight for the brightness pill
- UPower for the charging chip
- wttr.in for hover weather

There is no notification daemon. `notify` is only a visual state, triggered over IPC if you want it.
