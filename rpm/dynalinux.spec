# The COPR workflow stamps these values from the exact Git revision being built.
%global commit     HEAD
%global shortcommit HEAD
%global commitdate  20260813000000
%global archive     dynalinux-%{commit}

%global debug_package %{nil}

Name:           dynalinux
Version:        0
Release:        0.%{commitdate}.%{shortcommit}%{?dist}
Summary:        Compact Dynamic Island-style widget for Hyprland

License:        MIT
URL:            https://github.com/Ali120B/dynalinux
Source0:        %{url}/archive/%{commit}.tar.gz#/%{name}-%{commit}.tar.gz

BuildArch:      noarch

Requires:       quickshell
Requires:       qt6-qtdeclarative
Requires:       qt6-qt5compat
Requires:       playerctl
Requires:       upower
Requires:       pulseaudio-utils
Requires:       pipewire
Requires:       fontconfig
Requires:       google-noto-sans-fonts

%description
DynaLinux is a native QML/Quickshell island widget for Hyprland. A small
black handle sits at the top of the screen and expands into a clock, media
player, settings, or timer.

%prep
%autosetup -n %{archive}

%build

%install
install -dm 755 %{buildroot}%{_datadir}/%{name}
cp -r quickshell %{buildroot}%{_datadir}/%{name}/

install -dm 755 %{buildroot}%{_bindir}
cat > %{buildroot}%{_bindir}/%{name} <<'EOF'
#!/usr/bin/env sh
HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
EXEC_LINE="exec-once = dynalinux"
MARKER_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/dynalinux/autostart-done"

if [ ! -f "$MARKER_FILE" ] && [ -d "$HYPR_DIR" ]; then
    target=""
    if [ -f "$HYPR_DIR/custom/execs.conf" ]; then
        target="$HYPR_DIR/custom/execs.conf"
    elif [ -f "$HYPR_DIR/hyprland.conf" ]; then
        target="$HYPR_DIR/hyprland.conf"
    fi

    if [ -n "$target" ] && ! grep -qF "dynalinux" "$target" 2>/dev/null; then
        printf '\n%%s\n' "$EXEC_LINE" >> "$target"
    fi

    mkdir -p "$(dirname "$MARKER_FILE")"
    touch "$MARKER_FILE"
fi

exec quickshell --path /usr/share/dynalinux/quickshell "$@"
EOF
chmod 755 %{buildroot}%{_bindir}/%{name}

%files
%license LICENSE
%doc README.md
%{_bindir}/%{name}
%{_datadir}/%{name}/

%changelog
* Thu Aug 13 2026 Ali120B <alibashmail2010@yahoo.com> - 0-0.20260813
- Initial DynaLinux package
