import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

Item {
    id: root

    property string mode: "idle"
    property string appName: ""
    property string title: ""
    property string body: ""
    property string artist: ""
    property int volume: 0
    property bool muted: false
    property string volumeKind: "audio"
    property bool playing: false
    property string artUrl: ""
    property bool mediaAvailable: false
    property string handleStyle: "bump"
    property string timeText: ""
    property string dateText: ""
    property string fontFamily: "Noto Sans"
    property string weatherIcon: ""
    property string weatherTemp: ""
    property bool weatherAvailable: false
    property bool showTimeInIdle: false
    property bool timerRunning: false
    property real timerProgress: 0
    property string timerText: "05:00"
    property int timerHours: 0
    property int timerMinutes: 5
    property int batteryPercent: -1
    property bool batteryCharging: false
    property real mediaPosition: 0
    property real mediaLength: 0
    property real normalizedMediaPosition: 0

    signal mediaTogglePlayingClicked()
    signal mediaNextClicked()
    signal mediaPreviousClicked()
    signal mediaSeekRequested(real positionSeconds)
    signal settingsClicked()
    signal toggleIdleTimeClicked()
    signal smallModeToggled()
    signal timerHoursAdjust(int delta)
    signal timerMinutesAdjust(int delta)
    signal timerStartClicked()
    signal timerResetClicked()

    readonly property color primaryText: "#f7f7f7"
    readonly property color secondaryText: "#7f7f7f"
    readonly property color dimText: "#c8c8c8"
    readonly property color accent: "#ffffff"

    readonly property real volumeProgress: root.muted ? 0 : Math.max(0, Math.min(1, root.volume / 100))
    readonly property real volumeHudProgress: Math.max(0, Math.min(1, (root.volumeMorph - 0.15) / 0.85))
    readonly property string volumeGlyph: {
        if (root.volumeKind === "brightness")
            return root.volume >= 50 ? "brightness_high" : "brightness_low";
        if (root.muted)
            return "volume_off";
        if (root.volume <= 0)
            return "volume_mute";
        return root.volume < 50 ? "volume_down" : "volume_up";
    }

    property real volumeMorph: 0

    readonly property bool isHover: root.mode === "hover"
    readonly property bool isExpanded: root.mode === "expanded"
    readonly property bool isSettings: root.mode === "settings"
    readonly property bool isTimer: root.mode === "timer"
    readonly property bool isCollapsed: root.mode === "idle"

    // --- Collapsed bump: vinyl + audio bars (no text, no chip) -----------------

    Item {
        id: collapsedBumpMedia

        anchors.fill: parent
        opacity: root.isCollapsed && root.handleStyle === "bump" ? 1 : 0
        visible: opacity > 0

        // Idle time text (only when showTimeInIdle is on and no media)
        Text {
            anchors.centerIn: parent
            text: root.timeText
            color: "#c0c0c0"
            font.family: root.fontFamily
            font.pixelSize: 11
            font.weight: Font.Bold
            visible: root.showTimeInIdle && !root.mediaAvailable
        }

        Item {
            id: vinyl

            x: 7
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            visible: root.mediaAvailable

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "#101010"

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: "#262626"
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.6
                    height: parent.height * 0.6
                    radius: width / 2
                    color: "#0c0c0c"
                    clip: true
                    border.width: 1
                    border.color: "#1f1f1f"

                    Image {
                        id: vinylArt

                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: root.artUrl !== "" && status === Image.Ready
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * 0.24
                        height: parent.height * 0.24
                        radius: width / 2
                        color: "#000000"
                    }
                }
            }

            RotationAnimation on rotation {
                from: 0
                to: 360
                duration: 5000
                loops: Animation.Infinite
                running: vinyl.visible && root.playing
            }
        }

        // Inline audio bars — replaced the old music_note chip
        Item {
            id: collapsedBars

            x: parent.width - width - 7
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            visible: root.mediaAvailable

            Row {
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: 3

                    Rectangle {
                        width: 2
                        radius: 1
                        color: root.playing ? "#e0e0e0" : "#505050"
                        anchors.verticalCenter: parent.verticalCenter
                        height: 3

                        SequentialAnimation on height {
                            running: root.playing
                            loops: Animation.Infinite

                            NumberAnimation {
                                to: [6, 8, 5][index]
                                duration: 280 + index * 80
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                to: 3
                                duration: 280 + index * 80
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
    }

    // --- Hover content: ALWAYS time + weather ------------------------------------

    Item {
        id: hoverContent

        anchors.fill: parent
        opacity: root.isHover ? 1 : 0
        visible: opacity > 0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 10

            Text {
                text: root.timeText
                color: root.primaryText
                font.family: root.fontFamily
                font.pixelSize: 15
                font.weight: Font.Bold
            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 4
                visible: root.weatherAvailable

                MIcon {
                    name: root.weatherIcon
                    size: 10
                    color: "#d8d8d8"
                }

                Text {
                    text: root.weatherTemp
                    color: root.dimText
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
            }
        }
    }

    // --- Expanded content: NO music (clock centered + settings) -----------------

    Item {
        id: expandedNoMusicContent

        anchors.fill: parent
        opacity: root.isExpanded && !root.mediaAvailable ? 1 : 0
        visible: opacity > 0

        // Large clock centered
        Text {
            id: clockText

            anchors.horizontalCenter: parent.horizontalCenter
            y: 26
            text: root.timeText
            color: root.primaryText
            font.family: root.fontFamily
            font.pixelSize: 52
            font.weight: Font.Bold
        }

        // Day + date below the clock
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: clockText.bottom
            anchors.topMargin: 2
            text: root.dateText
            color: root.dimText
            font.family: root.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        // Battery (top-right)
        RowLayout {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 10
            anchors.rightMargin: 14
            spacing: 3
            visible: root.batteryPercent >= 0

            MIcon {
                name: root.batteryCharging ? "bolt" : "battery_5_bar"
                size: 11
                color: "#c8c8c8"
            }

            Text {
                text: root.batteryPercent + "%"
                color: "#c8c8c8"
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
        }

        // Settings icon top-left
        Item {
            width: 24
            height: 24
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 10
            anchors.leftMargin: 12

            MIcon {
                anchors.centerIn: parent
                name: "settings"
                size: 16
                color: "#a0a0a0"
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.settingsClicked()
            }
        }
    }

    // --- Expanded content: WITH music (Apple Dynamic Island style) ---------------

    Item {
        id: expandedMusicContent

        anchors.fill: parent
        opacity: root.isExpanded && root.mediaAvailable ? 1 : 0
        visible: opacity > 0

        // --- Status bar row: time + settings icons (top-left), battery (top-right) ---
        Row {
            x: 20
            y: 6
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.timeText
                color: root.primaryText
                font.family: root.fontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
            }

            // Settings icon
            Item {
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter

                MIcon {
                    anchors.centerIn: parent
                    name: "settings"
                    size: 14
                    color: "#a0a0a0"
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.settingsClicked()
                }
            }
        }

        // Battery (top-right)
        RowLayout {
            x: parent.width - 20 - width
            y: 8
            spacing: 3
            visible: root.batteryPercent >= 0

            MIcon {
                name: root.batteryCharging ? "bolt" : "battery_5_bar"
                size: 11
                color: "#c8c8c8"
            }

            Text {
                text: root.batteryPercent + "%"
                color: "#c8c8c8"
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
        }

        // --- Album art ---
        Rectangle {
            x: 16
            y: 30
            width: 50
            height: 50
            radius: 25
            clip: true
            color: "#1a1a1a"
            border.width: 1
            border.color: "#222222"

            Image {
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: root.artUrl !== "" && status === Image.Ready
            }
        }

        // --- Title + Artist ---
        Column {
            x: 80
            y: 34
            spacing: 4

            Text {
                text: root.title
                color: root.primaryText
                font.family: root.fontFamily
                font.pixelSize: 14
                font.weight: Font.Bold
                elide: Text.ElideRight
                width: 200
            }

            Text {
                text: root.artist
                color: root.secondaryText
                font.family: root.fontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
                width: 200
            }
        }

        // --- Audio bars (right side of content area) ---
        Item {
            x: parent.width - 40
            y: 38
            width: 14
            height: 20

            Row {
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: 3

                    Rectangle {
                        width: 2
                        radius: 1
                        color: root.playing ? "#e0e0e0" : "#505050"
                        anchors.verticalCenter: parent.verticalCenter
                        height: 3

                        SequentialAnimation on height {
                            running: root.playing
                            loops: Animation.Infinite

                            NumberAnimation {
                                to: [8, 12, 6][index]
                                duration: 280 + index * 80
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                to: 3
                                duration: 280 + index * 80
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }

        // --- Timeline ---
        Item {
            x: 16
            y: 84
            width: parent.width - 32
            height: 8

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "#262626"
            }

            Rectangle {
                width: parent.width * root.normalizedMediaPosition
                height: parent.height
                radius: height / 2
                color: "#fafafa"

                Behavior on width {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const ratio = mouse.x / parent.width;
                    root.mediaSeekRequested(ratio * root.mediaLength);
                }
            }
        }

        // --- Time labels ---
        Text {
            x: 16
            y: 92
            text: root.formatMediaTime(root.mediaPosition)
            color: root.secondaryText
            font.family: root.fontFamily
            font.pixelSize: 10
        }

        Text {
            x: parent.width - 16 - width
            y: 92
            text: "-" + root.formatMediaTime(Math.max(0, root.mediaLength - root.mediaPosition))
            color: root.secondaryText
            font.family: root.fontFamily
            font.pixelSize: 10
        }

        // --- Controls ---
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 108
            spacing: 24

            // Previous
            Item {
                width: 28
                height: 28

                MIcon {
                    anchors.centerIn: parent
                    name: "skip_previous"
                    size: 22
                    color: root.primaryText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.mediaPreviousClicked()
                }
            }

            // Play / Pause
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: root.primaryText

                MIcon {
                    anchors.centerIn: parent
                    name: root.playing ? "pause" : "play_arrow"
                    size: 18
                    color: "#000000"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.mediaTogglePlayingClicked()
                }
            }

            // Next
            Item {
                width: 28
                height: 28

                MIcon {
                    anchors.centerIn: parent
                    name: "skip_next"
                    size: 22
                    color: root.primaryText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.mediaNextClicked()
                }
            }
        }
    }

    // --- Settings page ------------------------------------------------------------

    Item {
        id: settingsContent

        anchors.fill: parent
        opacity: root.isSettings ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 160 } }

        // Header: title + close (gear) icon
        RowLayout {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 12
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 8

            Text {
                text: "Settings"
                color: root.primaryText
                font.family: root.fontFamily
                font.pixelSize: 14
                font.weight: Font.Bold
            }

            Item {
                Layout.fillWidth: true
                height: 1
            }

            Item {
                width: 20
                height: 20

                MIcon {
                    anchors.centerIn: parent
                    name: "settings"
                    size: 15
                    color: "#a0a0a0"
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.settingsClicked()
                }
            }
        }

        // --- Toggles ---
        Column {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 44
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 18

            RowLayout {
                width: parent.width
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Small mode"
                    color: root.dimText
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                ToggleSwitch {
                    checked: root.handleStyle === "strip"
                    onToggled: root.smallModeToggled()
                }
            }

            RowLayout {
                width: parent.width
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Show clock in idle"
                    color: root.dimText
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                ToggleSwitch {
                    checked: root.showTimeInIdle
                    onToggled: root.toggleIdleTimeClicked()
                }
            }
        }
    }

    // --- Volume / brightness HUD ------------------------------------------------

    Item {
        id: volumeContent

        anchors.fill: parent
        opacity: root.volumeHudProgress
        visible: opacity > 0.001
        scale: 0.92 + 0.08 * root.volumeHudProgress

        Item {
            id: volumeBar

            anchors.centerIn: parent
            width: Math.max(0, parent.width - 32)
            height: Math.min(26, Math.max(10, parent.height - 16))

            readonly property real glyphLeft: 9
            readonly property real fillWidth: volumeBar.width * root.volumeProgress

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "#26ffffff"
            }

            MIcon {
                x: volumeBar.glyphLeft
                anchors.verticalCenter: parent.verticalCenter
                name: root.volumeGlyph
                size: 15
                filled: true
                color: "#8b8b90"
            }

            Item {
                width: volumeBar.fillWidth
                height: parent.height
                clip: true

                Rectangle {
                    width: volumeBar.width
                    height: volumeBar.height
                    radius: height / 2
                    color: "#fafafa"
                }

                MIcon {
                    x: volumeBar.glyphLeft
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.volumeGlyph
                    size: 15
                    filled: true
                    color: "#0b0b0d"
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    // --- Notification content ---------------------------------------------------

    RowLayout {
        id: notificationContent

        anchors.fill: parent
        spacing: 12
        opacity: root.mode === "notify" ? 1 : 0
        visible: opacity > 0

        Rectangle {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            radius: 15
            color: "#000000"
            border.width: 1
            border.color: "#202020"

            Text {
                anchors.centerIn: parent
                text: "!"
                color: root.accent
                font.family: root.fontFamily
                font.pixelSize: 22
                font.bold: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.appName
                color: root.secondaryText
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: root.title
                color: root.primaryText
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: root.body
                color: root.secondaryText
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 12
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 210
            }
        }
    }

    // --- Timer page ------------------------------------------------------------

    Item {
        id: timerContent

        anchors.fill: parent
        opacity: root.isTimer ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 160 } }

        Row {
            anchors.centerIn: parent
            spacing: 16

            Item {
                id: timerRing

                width: 88
                height: 88

                Shape {
                    anchors.fill: parent
                    antialiasing: true

                    ShapePath {
                        strokeWidth: 5
                        strokeColor: "#2c2c2c"
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap

                        PathAngleArc {
                            centerX: timerRing.width / 2
                            centerY: timerRing.height / 2
                            radiusX: 36
                            radiusY: 36
                            startAngle: 0
                            sweepAngle: 360
                        }
                    }

                    ShapePath {
                        strokeWidth: 5
                        strokeColor: "#ff8a1a"
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap

                        PathAngleArc {
                            centerX: timerRing.width / 2
                            centerY: timerRing.height / 2
                            radiusX: 36
                            radiusY: 36
                            startAngle: -90
                            sweepAngle: 360 * root.timerProgress
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.timerText
                    color: root.primaryText
                    font.family: root.fontFamily
                    font.pixelSize: root.timerText.length > 5 ? 16 : 20
                    font.weight: Font.Bold
                }
            }

            Grid {
                columns: 2
                rows: 2
                rowSpacing: 8
                columnSpacing: 8

                Rectangle {
                    width: 92
                    height: 36
                    radius: 10
                    color: "#2a2a2a"

                    Text {
                        anchors.centerIn: parent
                        text: root.timerHours + " h"
                        color: root.primaryText
                        font.family: root.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            root.timerHoursAdjust(mouse.button === Qt.RightButton ? -1 : 1);
                        }
                    }
                }

                Rectangle {
                    width: 92
                    height: 36
                    radius: 10
                    color: "#2a2a2a"

                    Text {
                        anchors.centerIn: parent
                        text: (root.timerMinutes < 10 ? "0" : "") + root.timerMinutes + " m"
                        color: root.primaryText
                        font.family: root.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            root.timerMinutesAdjust(mouse.button === Qt.RightButton ? -1 : 1);
                        }
                    }
                }

                Rectangle {
                    width: 92
                    height: 36
                    radius: 10
                    color: "#ff8a1a"

                    Text {
                        anchors.centerIn: parent
                        text: root.timerRunning ? "Stop" : "Start"
                        color: "#111111"
                        font.family: root.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.timerStartClicked()
                    }
                }

                Rectangle {
                    width: 92
                    height: 36
                    radius: 10
                    color: "#2a2a2a"

                    Text {
                        anchors.centerIn: parent
                        text: "Reset"
                        color: root.primaryText
                        font.family: root.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.timerResetClicked()
                    }
                }
            }
        }
    }

    // Helper function for media time formatting
    function formatMediaTime(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        const m = Math.floor(s / 60);
        const sec = s % 60;
        return m + ":" + (sec < 10 ? "0" : "") + sec;
    }
}
