import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland

Scope {
    id: root

    property string mode: "idle"
    property string appName: "DynaLinux"
    property string title: "Ready"
    property string body: "Waiting for a signal"
    property string artist: ""
    property string artUrl: ""
    property int volume: 42
    property bool muted: false
    property bool volumeIndicatorVisible: false
    property string volumeKind: "audio"
    property bool playing: true
    property bool demoRunning: false
    property bool pointerInside: false
    property bool expandedOpen: false
    property bool settingsOpen: false
    property bool timerOpen: false
    property bool timerRunning: false
    property int timerHours: 0
    property int timerMinutes: 5
    property int timerDurationSec: 300
    property double timerEndsAt: 0
    property int timerRemainingSec: 300
    property double timerClockMs: 0
    property bool liveLinksEnabled: true
    property bool liveLinksPrimed: false
    property string backlightPath: ""
    property int backlightMaxRaw: 0
    property date currentDateTime: new Date()
    property string handleStyle: "bump"
    property var activePlayer: null
    property string lastTrackKey: ""
    property real lastSinkVolume: -1
    property bool lastSinkMuted: false
    property int lastBatteryLevel: -1
    property bool lastBatteryPluggedIn: false
    property int lastBrightnessLevel: -1
    property int demoStep: 0
    property bool trayBatteryDismissed: false
    property bool showTimeInIdle: false
    property bool mediaLiked: false

    property real mediaPosition: 0
    property real mediaLength: 0

    property string weatherCondition: ""
    property string weatherTemp: ""
    property string weatherIcon: ""
    property bool weatherAvailable: false
    property double lastWeatherFetchAt: 0

    readonly property bool interactionOpen: root.pointerInside || root.expandedOpen
    readonly property bool trayVisible: root.handleStyle === "bump" && !root.interactionOpen && root.visualMode === "idle"
    readonly property bool volumeHudMode: root.volumeIndicatorVisible && root.mode === "idle"
    readonly property bool expandedWithMedia: root.expandedOpen && root.mediaAvailable
    readonly property string visualMode: {
        if (root.volumeHudMode) return "volume";
        if (root.mode === "notify") return "notify";
        if (root.pointerInside || root.expandedOpen) {
            if (root.timerOpen)
                return "timer";
            return root.settingsOpen ? "settings" : "expanded";
        }
        return root.mode;
    }
    readonly property int idleTopMargin: 0
    readonly property int expandedTopMargin: 0
    readonly property int reservedZone: root.handleStyle === "strip" ? 0 : 24
    readonly property int windowHeight: 200
    readonly property int bumpWidth: 156
    readonly property int bumpHeight: 24
    readonly property int stripWidth: 98
    readonly property int stripHeight: 4
    readonly property int expandedNoMusicWidth: 340
    readonly property int expandedNoMusicHeight: 140
    readonly property int expandedWithMusicWidth: 400
    readonly property int expandedWithMusicHeight: 152
    readonly property int notifyWidth: 438
    readonly property int notifyHeight: 74
    readonly property int volumeWidth: 244
    readonly property int volumeHeight: 48
    readonly property int timerWidth: 368
    readonly property int timerHeight: 118
    readonly property string fontFamily: "Noto Sans"
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property string clockTimeText: root.formatClockTime(root.currentDateTime)
    readonly property string clockDateText: root.formatClockDate(root.currentDateTime)
    readonly property bool mediaAvailable: root.liveLinksEnabled && root.hasActiveMedia()
    readonly property int batteryPercent: root.batteryAvailable() ? root.batteryLevel() : -1
    readonly property bool batteryCharging: root.batteryAvailable() ? root.batteryPluggedIn() : false
    readonly property real normalizedMediaPosition: root.mediaLength > 0 ? Math.max(0, Math.min(1, root.mediaPosition / root.mediaLength)) : 0
    readonly property bool mediaShuffleActive: root.activePlayer?.shuffle ?? false
    readonly property real timerProgress: {
        if (!root.timerRunning || root.timerDurationSec <= 0 || root.timerEndsAt <= 0)
            return 0;
        const startAt = root.timerEndsAt - root.timerDurationSec * 1000;
        return Math.max(0, Math.min(1, (root.timerClockMs - startAt) / (root.timerDurationSec * 1000)));
    }
    readonly property string timerText: root.formatTimer(root.timerRunning ? root.timerRemainingSec : root.timerDurationSec)

    function targetWidth() {
        switch (root.visualMode) {
        case "notify":
            return root.notifyWidth;
        case "expanded":
            return root.expandedWithMedia ? root.expandedWithMusicWidth : root.expandedNoMusicWidth;
        case "volume":
            return root.volumeWidth;
        case "settings":
            return root.expandedWithMedia ? root.expandedWithMusicWidth : root.expandedNoMusicWidth;
        case "timer":
            return root.timerWidth;
        default:
            return root.handleStyle === "strip" ? root.stripWidth : root.bumpWidth;
        }
    }

    function targetHeight() {
        switch (root.visualMode) {
        case "notify":
            return root.notifyHeight;
        case "expanded":
            return root.expandedWithMedia ? root.expandedWithMusicHeight : root.expandedNoMusicHeight;
        case "volume":
            return root.volumeHeight;
        case "settings":
            return root.expandedWithMedia ? root.expandedWithMusicHeight : root.expandedNoMusicHeight;
        case "timer":
            return root.timerHeight;
        default:
            return root.handleStyle === "strip" ? root.stripHeight : root.bumpHeight;
        }
    }

    function targetY() {
        return root.visualMode === "idle" && !root.interactionOpen ? root.idleTopMargin : root.expandedTopMargin;
    }

    function hold(milliseconds) {
        collapseTimer.interval = milliseconds;
        collapseTimer.restart();
    }

    function keepInteractionOpen() {
        hoverLeaveTimer.stop();
        root.pointerInside = true;
        root.expandedOpen = true;
    }

    function scheduleInteractionClose() {
        hoverLeaveTimer.restart();
    }

    function boolFromIpc(value) {
        return value === true || value === "true" || value === "1" || value === "on" || value === "yes";
    }

    function pad2(value) {
        return value < 10 ? "0" + value : String(value);
    }

    function formatClockTime(value) {
        const date = new Date(value);
        return root.pad2(date.getHours()) + ":" + root.pad2(date.getMinutes());
    }

    function formatClockDate(value) {
        const date = new Date(value);
        const weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        return date.getDate() + "," + weekdays[date.getDay()];
    }

    function formatTimer(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        const hours = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = s % 60;

        if (hours > 0)
            return hours + ":" + root.pad2(m) + ":" + root.pad2(sec);

        return root.pad2(m) + ":" + root.pad2(sec);
    }

    function formatMediaTime(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        const m = Math.floor(s / 60);
        const sec = s % 60;
        return m + ":" + (sec < 10 ? "0" : "") + sec;
    }

    function showIdle() {
        collapseTimer.stop();
        root.mode = "idle";
        root.expandedOpen = false;
        root.settingsOpen = false;
        root.timerOpen = false;
        root.title = "Ready";
        root.body = "Waiting for a signal";

        if (root.liveLinksEnabled) {
            root.chooseActivePlayer(null);
            if (root.hasActiveMedia())
                root.syncMediaFields(root.activePlayer);
        }
    }

    function setHandleStyle(style) {
        if (style === "strip" || style === "bump")
            root.handleStyle = style;
    }

    function toggleHandleStyle() {
        root.handleStyle = root.handleStyle === "strip" ? "bump" : "strip";
    }

    function toggleIdleTime() {
        root.showTimeInIdle = !root.showTimeInIdle;
    }

    function toggleTimerPanel() {
        root.keepInteractionOpen();
        root.expandedOpen = true;
        root.settingsOpen = false;
        root.timerOpen = !root.timerOpen;
    }

    function syncTimerDuration() {
        root.timerDurationSec = root.timerHours * 3600 + root.timerMinutes * 60;
        if (!root.timerRunning)
            root.timerRemainingSec = root.timerDurationSec;
    }

    function bumpTimerHours(delta) {
        if (root.timerRunning)
            return;

        root.timerHours = (root.timerHours + delta + 24) % 24;
        root.syncTimerDuration();
    }

    function bumpTimerMinutes(delta) {
        if (root.timerRunning)
            return;

        root.timerMinutes = (root.timerMinutes + delta + 60) % 60;
        root.syncTimerDuration();
    }

    function startTimer() {
        root.syncTimerDuration();
        if (root.timerDurationSec <= 0)
            return;

        root.timerEndsAt = Date.now() + root.timerDurationSec * 1000;
        root.timerRemainingSec = root.timerDurationSec;
        root.timerRunning = true;
    }

    function stopTimer() {
        root.timerRunning = false;
        root.timerEndsAt = 0;
        root.timerRemainingSec = root.timerDurationSec;
    }

    function resetTimer() {
        root.timerRunning = false;
        root.timerEndsAt = 0;
        root.syncTimerDuration();
    }

    function tickTimer() {
        if (!root.timerRunning)
            return;

        const remaining = Math.max(0, Math.ceil((root.timerEndsAt - Date.now()) / 1000));
        root.timerRemainingSec = remaining;

        if (remaining <= 0) {
            root.timerRunning = false;
            root.timerEndsAt = 0;
            root.showNotification("Timer", "Time is up", "DynaLinux");
            root.timerRemainingSec = root.timerDurationSec;
        }
    }

    function showNotification(summary, message, app) {
        root.appName = app || "Notification";
        root.title = summary || "New notification";
        root.body = message || "";
        root.artUrl = "";
        root.mode = "notify";
        root.hold(5200);
    }

    function showVolume(level, isMuted) {
        root.volume = Math.max(0, Math.min(100, Number(level)));
        root.muted = isMuted;
        root.volumeKind = "audio";
        root.volumeIndicatorVisible = true;
        volumeIndicatorTimer.restart();
    }

    function showBrightness(level) {
        root.volume = Math.max(0, Math.min(100, Number(level)));
        root.muted = false;
        root.volumeKind = "brightness";
        root.volumeIndicatorVisible = true;
        volumeIndicatorTimer.restart();
    }

    // --- MPRIS -----------------------------------------------------------------

    function trackTitle(player) {
        return player?.trackTitle || "Unknown track";
    }

    function trackArtist(player) {
        return player?.trackArtist || player?.identity || "Unknown artist";
    }

    function trackArtUrl(player) {
        return player?.trackArtUrl || "";
    }

    function trackKey(player) {
        if (!player)
            return "";
        return [player.uniqueId || player.dbusName || "", root.trackTitle(player), root.trackArtist(player), player.isPlaying ? "playing" : "paused"].join("|");
    }

    function syncMediaFields(player) {
        if (!player)
            return;

        root.title = root.trackTitle(player);
        root.artist = root.trackArtist(player);
        root.artUrl = root.trackArtUrl(player);
        root.playing = player.isPlaying;
        root.mediaPosition = player.position || 0;
        root.mediaLength = player.length || 0;
    }

    function hasActiveMedia() {
        const player = root.activePlayer;
        if (!player)
            return false;
        return player.isPlaying || root.trackTitle(player) !== "Unknown track";
    }

    function chooseActivePlayer(preferredPlayer) {
        const players = Mpris.players.values;

        if (preferredPlayer) {
            root.activePlayer = preferredPlayer;
            return;
        }

        for (let i = 0; i < players.length; i += 1) {
            if (players[i].isPlaying) {
                root.activePlayer = players[i];
                return;
            }
        }

        root.activePlayer = players.length > 0 ? players[0] : null;
    }

    function trackPlayerChanged(player) {
        if (!root.liveLinksEnabled)
            return;

        root.chooseActivePlayer(player);
        root.syncMediaFields(root.activePlayer);
    }

    function mediaTogglePlaying() {
        const player = root.activePlayer;
        if (player)
            player.togglePlaying();
    }

    function mediaNext() {
        const player = root.activePlayer;
        if (player)
            player.next();
    }

    function mediaPrevious() {
        const player = root.activePlayer;
        if (player)
            player.previous();
    }

    function mediaSeek(positionSeconds) {
        const player = root.activePlayer;
        if (player)
            player.position = positionSeconds;
    }

    function mediaToggleShuffle() {
        const player = root.activePlayer;
        if (!player)
            return;
        if (player.shuffleSupported === false)
            return;
        player.shuffle = !player.shuffle;
    }

    function mediaToggleLike() {
        root.mediaLiked = !root.mediaLiked;
    }

    // --- Volume (PipeWire) -----------------------------------------------------

    function sinkVolumePercent() {
        const rawVolume = root.audioSink?.audio?.volume ?? 0;
        return Math.max(0, Math.min(100, Math.round(rawVolume * 100)));
    }

    function sinkMuted() {
        return root.audioSink?.audio?.muted ?? false;
    }

    function maybeShowVolumeFromSink() {
        if (!root.liveLinksEnabled)
            return;

        const nextVolume = root.sinkVolumePercent();
        const nextMuted = root.sinkMuted();

        if (!root.liveLinksPrimed) {
            root.lastSinkVolume = nextVolume;
            root.lastSinkMuted = nextMuted;
            return;
        }

        if (nextVolume !== root.lastSinkVolume || nextMuted !== root.lastSinkMuted) {
            root.lastSinkVolume = nextVolume;
            root.lastSinkMuted = nextMuted;
            root.showVolume(nextVolume, nextMuted);
        }
    }

    // --- Battery (UPower) ------------------------------------------------------

    function batteryAvailable() {
        return UPower.displayDevice?.isLaptopBattery ?? false;
    }

    function batteryLevel() {
        return Math.max(0, Math.min(100, Math.round((UPower.displayDevice?.percentage ?? 1) * 100)));
    }

    function batteryPluggedIn() {
        const chargeState = UPower.displayDevice?.state;
        return chargeState === UPowerDeviceState.Charging || chargeState === UPowerDeviceState.PendingCharge;
    }

    function maybeShowBattery(forceStateEvent) {
        if (!root.liveLinksEnabled || !root.batteryAvailable())
            return;

        const nextLevel = root.batteryLevel();
        const nextPluggedIn = root.batteryPluggedIn();

        if (!root.liveLinksPrimed) {
            root.lastBatteryLevel = nextLevel;
            root.lastBatteryPluggedIn = nextPluggedIn;
            return;
        }

        if (forceStateEvent && nextPluggedIn !== root.lastBatteryPluggedIn)
            root.trayBatteryDismissed = false;

        root.lastBatteryLevel = nextLevel;
        root.lastBatteryPluggedIn = nextPluggedIn;
    }

    // --- Brightness (sysfs) ----------------------------------------------------

    function updateRawBrightness(raw) {
        if (!isFinite(raw) || raw < 0 || root.backlightMaxRaw <= 0)
            return;
        root.updatePolledBrightness(raw * 100 / root.backlightMaxRaw);
    }

    function updatePolledBrightness(rawLevel) {
        if (!isFinite(rawLevel) || rawLevel < 0)
            return;

        const nextLevel = Math.max(0, Math.min(100, Math.round(rawLevel)));

        if (root.lastBrightnessLevel < 0) {
            root.lastBrightnessLevel = nextLevel;
            return;
        }

        if (nextLevel !== root.lastBrightnessLevel) {
            root.lastBrightnessLevel = nextLevel;
            root.showBrightness(nextLevel);
        }
    }

    // --- Weather (wttr.in) -----------------------------------------------------

    function isNightNow() {
        const hours = root.currentDateTime.getHours();
        return hours < 6 || hours >= 19;
    }

    function weatherIconName(condition) {
        const c = (condition || "").toLowerCase();

        if (c.indexOf("thunder") !== -1)
            return "thunderstorm";
        if (c.indexOf("snow") !== -1 || c.indexOf("sleet") !== -1 || c.indexOf("ice") !== -1)
            return "ac_unit";
        if (c.indexOf("rain") !== -1 || c.indexOf("drizzle") !== -1 || c.indexOf("shower") !== -1)
            return "rainy";
        if (c.indexOf("fog") !== -1 || c.indexOf("mist") !== -1 || c.indexOf("haze") !== -1 || c.indexOf("smoke") !== -1)
            return "foggy";
        if (c.indexOf("wind") !== -1)
            return "air";
        if (c.indexOf("partly") !== -1 || c.indexOf("patchy") !== -1)
            return root.isNightNow() ? "nights_stay" : "partly_cloudy_day";
        if (c.indexOf("cloud") !== -1 || c.indexOf("overcast") !== -1)
            return "cloud";
        if (c.indexOf("clear") !== -1 || c.indexOf("sunny") !== -1)
            return root.isNightNow() ? "nights_stay" : "sunny";
        return "";
    }

    function applyWeather(text) {
        const trimmed = text.trim();
        if (trimmed === "" || trimmed.indexOf("|") === -1)
            return;

        const parts = trimmed.split("|");
        const condition = parts[0] || "";
        const temperature = (parts[1] || "").trim();

        root.weatherCondition = condition;
        root.weatherTemp = temperature;
        root.weatherIcon = root.weatherIconName(condition);
        root.weatherAvailable = condition !== "" && temperature !== "";
        root.lastWeatherFetchAt = Date.now();
    }

    function refreshWeather() {
        if (weatherProc.running)
            return;
        weatherProc.exec(["sh", "-c", "curl -s --max-time 6 'https://wttr.in/?format=%C|%t' 2>/dev/null | head -1"]);
    }

    // --- Demo -------------------------------------------------------------------

    function demo() {
        const step = root.demoStep % 3;
        root.demoStep += 1;

        if (step === 0) {
            root.showNotification("Build finished", "DynaLinux rendered its first island.", "DynaLinux");
        } else if (step === 1) {
            root.showVolume(68, false);
        } else {
            root.showIdle();
        }
    }

    function focusedScreen() {
        const focusedMonitor = Hyprland.focusedMonitor;

        if (focusedMonitor) {
            for (let i = 0; i < Quickshell.screens.length; i += 1) {
                if (Quickshell.screens[i].name === focusedMonitor.name)
                    return Quickshell.screens[i];
            }
        }

        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function primeLiveLinks() {
        root.chooseActivePlayer(null);
        root.syncMediaFields(root.activePlayer);
        root.lastTrackKey = root.trackKey(root.activePlayer);
        root.lastSinkVolume = root.sinkVolumePercent();
        root.lastSinkMuted = root.sinkMuted();

        if (root.batteryAvailable()) {
            root.lastBatteryLevel = root.batteryLevel();
            root.lastBatteryPluggedIn = root.batteryPluggedIn();
        }

        root.liveLinksPrimed = true;
    }

    // --- Timers -----------------------------------------------------------------

    Timer {
        id: collapseTimer
        repeat: false
        onTriggered: root.showIdle()
    }

    Timer {
        id: hoverLeaveTimer
        interval: 140
        repeat: false
        onTriggered: {
            root.pointerInside = false;
            root.expandedOpen = false;
            root.settingsOpen = false;
            root.timerOpen = false;
        }
    }

    Timer {
        id: demoLoopTimer
        interval: 2600
        repeat: true
        running: root.demoRunning
        onTriggered: root.demo()
    }

    Timer {
        id: volumeIndicatorTimer
        interval: 1800
        repeat: false
        onTriggered: root.volumeIndicatorVisible = false
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.currentDateTime = new Date()
    }

    Timer {
        interval: 16
        repeat: true
        running: root.timerRunning
        triggeredOnStart: true
        onTriggered: {
            root.timerClockMs = Date.now();
            root.tickTimer();
        }
    }

    Timer {
        id: liveLinkPrimeTimer
        interval: 900
        repeat: false
        running: true
        onTriggered: root.primeLiveLinks()
    }

    Timer {
        id: mediaPositionTimer
        interval: 1000
        repeat: true
        running: root.expandedOpen && root.mediaAvailable
        onTriggered: {
            const player = root.activePlayer;
            if (player) {
                root.mediaPosition = player.position || 0;
                root.mediaLength = player.length || 0;
            }
        }
    }

    // --- Backlight --------------------------------------------------------------

    Process {
        id: backlightProbeProc

        running: true
        command: ["sh", "-c", "for dev in /sys/class/backlight/*; do [ -r \"$dev/brightness\" ] && [ -r \"$dev/max_brightness\" ] || continue; printf '%s\\n' \"$dev\"; break; done"]

        stdout: StdioCollector {
            onStreamFinished: root.backlightPath = text.trim()
        }
    }

    Timer {
        interval: 700
        repeat: true
        running: root.liveLinksEnabled && root.backlightPath !== ""
        triggeredOnStart: true
        onTriggered: {
            backlightMaxFile.reload();
            backlightFile.reload();
        }
    }

    FileView {
        id: backlightMaxFile

        path: root.backlightPath === "" ? "" : root.backlightPath + "/max_brightness"
        printErrors: false
        onLoaded: root.backlightMaxRaw = Number(backlightMaxFile.text().trim())
    }

    FileView {
        id: backlightFile

        path: root.backlightPath === "" ? "" : root.backlightPath + "/brightness"
        printErrors: false
        onLoaded: root.updateRawBrightness(Number(backlightFile.text().trim()))
    }

    // --- Weather ----------------------------------------------------------------

    Timer {
        interval: 900000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshWeather()
    }

    Process {
        id: weatherProc

        stdout: StdioCollector {
            onStreamFinished: root.applyWeather(text)
        }
    }

    // --- Connections ------------------------------------------------------------

    PwObjectTracker {
        objects: [root.audioSink]
    }

    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData
            target: modelData

            Component.onCompleted: root.trackPlayerChanged(modelData)
            function onPlaybackStateChanged() { root.trackPlayerChanged(modelData); }
            function onPostTrackChanged() { root.trackPlayerChanged(modelData); }
        }
    }

    Connections {
        target: root.audioSink?.audio ?? null

        function onVolumeChanged() { root.maybeShowVolumeFromSink(); }
        function onMutedChanged() { root.maybeShowVolumeFromSink(); }
    }

    Connections {
        target: UPower.displayDevice ?? null

        function onPercentageChanged() { root.maybeShowBattery(false); }
        function onStateChanged() { root.maybeShowBattery(true); }
    }

    onInteractionOpenChanged: {
        if (root.interactionOpen && Date.now() - root.lastWeatherFetchAt > 600000)
            root.refreshWeather();
    }

    // --- UI ---------------------------------------------------------------------

    PanelWindow {
        id: islandWindow

        screen: root.focusedScreen()
        color: "transparent"
        exclusiveZone: root.reservedZone
        exclusionMode: ExclusionMode.Normal
        implicitHeight: root.windowHeight
        visible: true

        WlrLayershell.namespace: "dynalinux"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        anchors {
            top: true
            left: true
            right: true
        }

        mask: Region {
            item: interactionMask
        }

        Item {
            anchors.fill: parent

            Item {
                id: interactionMask

                readonly property real maskPadding: 8
                readonly property bool trayLeftVisible: trayLeft.visible && trayLeft.opacity > 0
                readonly property real islandRightEdge: island.x + island.width
                readonly property real islandBottomEdge: island.y + island.height
                readonly property real trayLeftEdge: trayLeftVisible ? trayLeft.x : island.x
                readonly property real leftEdge: Math.min(island.x, trayLeftEdge)
                readonly property real rightEdge: islandRightEdge
                readonly property real bottomEdge: islandBottomEdge

                x: Math.max(0, leftEdge - maskPadding)
                y: Math.max(0, island.y - maskPadding)
                width: Math.min(parent.width - x, rightEdge - x + maskPadding)
                height: Math.min(parent.height - y, bottomEdge - y + maskPadding)
            }

            IslandSurface {
                id: island

                z: 10
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.targetY()
                targetW: root.targetWidth()
                targetH: root.targetHeight()
                mode: root.visualMode
                handleStyle: root.handleStyle
                appName: root.appName
                title: root.title
                body: root.body
                artist: root.artist
                volume: root.volume
                muted: root.muted
                volumeKind: root.volumeKind
                playing: root.playing
                artUrl: root.artUrl
                mediaAvailable: root.mediaAvailable
                fontFamily: root.fontFamily
                timeText: root.clockTimeText
                dateText: root.clockDateText
                weatherIcon: root.weatherIcon
                weatherTemp: root.weatherTemp
                weatherAvailable: root.weatherAvailable
                showTimeInIdle: root.showTimeInIdle
                batteryPercent: root.batteryPercent
                batteryCharging: root.batteryCharging
                mediaPosition: root.mediaPosition
                mediaLength: root.mediaLength
                normalizedMediaPosition: root.normalizedMediaPosition
                shuffleActive: root.mediaShuffleActive
                mediaLiked: root.mediaLiked
                timerRunning: root.timerRunning
                timerProgress: root.timerProgress
                timerText: root.timerText
                timerHours: root.timerHours
                timerMinutes: root.timerMinutes

                onMediaTogglePlayingClicked: root.mediaTogglePlaying()
                onMediaNextClicked: root.mediaNext()
                onMediaPreviousClicked: root.mediaPrevious()
                onMediaSeekRequested: function(pos) { root.mediaSeek(pos); }
                onMediaShuffleClicked: root.mediaToggleShuffle()
                onMediaLikeClicked: root.mediaToggleLike()
                onSettingsClicked: {
                    root.keepInteractionOpen();
                    root.timerOpen = false;
                    root.settingsOpen = !root.settingsOpen;
                }
                onSmallModeToggled: root.toggleHandleStyle()
                onToggleIdleTimeClicked: root.toggleIdleTime()
                onTimerHoursAdjust: function(delta) { root.bumpTimerHours(delta); }
                onTimerMinutesAdjust: function(delta) { root.bumpTimerMinutes(delta); }
                onTimerStartClicked: root.timerRunning ? root.stopTimer() : root.startTimer()
                onTimerResetClicked: root.resetTimer()
            }

            Row {
                id: trayLeft

                z: 30
                x: island.x - width - 8
                y: island.y + Math.max(0, (island.height - height) / 2)
                spacing: 6
                opacity: root.trayVisible ? 1 : 0
                visible: opacity > 0

                TrayIndicator {
                    icon: "bolt"
                    iconSize: 11
                    iconColor: "#4ade80"
                    circular: true
                    active: root.trayVisible && root.batteryAvailable() && root.batteryPluggedIn()
                    dismissed: root.trayBatteryDismissed
                    onClicked: root.trayBatteryDismissed = true
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                id: islandHitbox

                z: 20
                anchors.horizontalCenter: island.horizontalCenter
                y: island.y
                width: island.width
                height: root.mode === "idle" && !root.interactionOpen ? Math.max(root.reservedZone, island.height) : island.height
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onEntered: root.keepInteractionOpen()
                onExited: root.scheduleInteractionClose()
                onPressed: function(mouse) {
                    if (root.volumeIndicatorVisible)
                        return;

                    if (mouse.button === Qt.RightButton) {
                        root.toggleTimerPanel();
                        return;
                    }

                    if (!root.expandedOpen) {
                        root.expandedOpen = true;
                        return;
                    }

                    mouse.accepted = false;
                }
            }
        }
    }

    IpcHandler {
        target: "dynalinux"

        function idle(): void {
            root.showIdle();
        }

        function handle(style: string): void {
            root.setHandleStyle(style);
        }

        function toggleHandle(): void {
            root.toggleHandleStyle();
        }

        function toggleIdleTime(): void {
            root.toggleIdleTime();
        }

        function live(enabled: string): void {
            root.liveLinksEnabled = root.boolFromIpc(enabled);
        }

        function notify(summary: string, message: string, app: string): void {
            root.showNotification(summary, message, app);
        }

        function volume(level: int, isMuted: string): void {
            root.showVolume(level, isMuted === "true" || isMuted === "muted" || isMuted === "1");
        }

        function brightness(level: int): void {
            root.showBrightness(level);
        }

        function weather(): void {
            root.refreshWeather();
        }

        function demo(): void {
            root.demo();
        }

        function demoLoop(): void {
            root.demoRunning = !root.demoRunning;
            if (root.demoRunning)
                root.demo();
        }
    }
}
