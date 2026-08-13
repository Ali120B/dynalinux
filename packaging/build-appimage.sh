#!/usr/bin/env bash
# Build a DynaLinux AppImage (bundles the QML config; uses system quickshell).
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build/appimage"
APPDIR="$BUILD/DynaLinux.AppDir"
OUT="$BUILD/DynaLinux-x86_64.AppImage"
ARCH="$(uname -m)"
APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${ARCH}.AppImage"

rm -rf "$BUILD"
mkdir -p "$APPDIR/usr/share/dynalinux" "$APPDIR/usr/bin" "$BUILD/tools"

cp -a "$ROOT/quickshell" "$APPDIR/usr/share/dynalinux/"

cat > "$APPDIR/AppRun" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$HERE/usr/share/dynalinux/quickshell"

if ! command -v quickshell >/dev/null 2>&1; then
  printf 'DynaLinux needs Quickshell installed on the system.\n' >&2
  printf 'Arch: paru -S quickshell-git\n' >&2
  printf 'Docs: https://quickshell.outfoxxed.me/docs/guide/install-setup/\n' >&2
  exit 1
fi

export QS_NO_RELOAD_POPUP="${QS_NO_RELOAD_POPUP:-1}"
exec quickshell --path "$CONFIG" "$@"
EOF
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/dynalinux.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=DynaLinux
Comment=Compact Dynamic Island for Hyprland
Exec=dynalinux
Icon=dynalinux
Categories=Utility;System;
Terminal=false
EOF

# Minimal embedded PNG icon (black rounded square) via Python if available
python3 - <<'PY' "$APPDIR/dynalinux.png" || true
import struct, zlib, sys
path = sys.argv[1]
w = h = 128
raw = b""
for y in range(h):
    raw += b"\x00"
    for x in range(w):
        # soft black pill-ish mark
        cx, cy = 64, 64
        dx, dy = (x - cx) / 50.0, (y - cy) / 28.0
        inside = dx*dx + dy*dy <= 1.0
        if inside:
            raw += bytes((8, 8, 8, 255))
        else:
            raw += bytes((0, 0, 0, 0))

def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)

ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
open(path, "wb").write(png)
print("wrote", path)
PY

if [ ! -f "$APPDIR/dynalinux.png" ]; then
  # fallback empty placeholder so appimagetool is happy
  printf '' > "$APPDIR/dynalinux.png"
fi

ln -sf dynalinux.png "$APPDIR/.DirIcon"

TOOL="$BUILD/tools/appimagetool"
if [ ! -x "$TOOL" ]; then
  echo "==> Downloading appimagetool"
  curl -fsSL -o "$TOOL" "$APPIMAGETOOL_URL"
  chmod +x "$TOOL"
fi

echo "==> Building AppImage"
(
  cd "$BUILD"
  ARCH="$ARCH" "$TOOL" --no-appstream "$APPDIR" "$OUT"
)

chmod +x "$OUT"
ls -lh "$OUT"
echo "Built: $OUT"
