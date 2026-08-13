import QtQuick
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
    property int batteryPercent: -1
    property bool batteryCharging: false
    property real mediaPosition: 0
    property real mediaLength: 0
    property real normalizedMediaPosition: 0
    property bool shuffleActive: false
    property bool mediaLiked: false
    property bool timerRunning: false
    property real timerProgress: 0
    property string timerText: "05:00"
    property int timerHours: 0
    property int timerMinutes: 5

    signal mediaTogglePlayingClicked()
    signal mediaNextClicked()
    signal mediaPreviousClicked()
    signal mediaSeekRequested(real positionSeconds)
    signal mediaShuffleClicked()
    signal mediaLikeClicked()
    signal settingsClicked()
    signal toggleIdleTimeClicked()
    signal smallModeToggled()
    signal timerHoursAdjust(int delta)
    signal timerMinutesAdjust(int delta)
    signal timerStartClicked()
    signal timerResetClicked()

    property real targetW: 0
    property real targetH: 0

    property real volumeMorph: 0

    readonly property bool expanded: mode !== "idle"
    readonly property real expandedBottomRadius: {
        const islandRadius = Math.min(height * 0.28, 24);
        return islandRadius + (height / 2 - islandRadius) * root.volumeMorph;
    }
    readonly property real bottomRadius: Math.max(1, Math.min(height / 2, expanded ? expandedBottomRadius : Math.min(height * 0.42, 8)))
    readonly property color surfaceColor: !expanded && handleStyle === "strip" ? "#0c0c0c" : "#000000"
    readonly property real antiCornerRadius: root.expanded || handleStyle === "strip" ? Math.min(3, height * 0.6) : Math.min(2.5, height * 0.12)

    transformOrigin: Item.Top

    Shape {
        id: antiCornerLeft

        x: -antiCornerLeft.width
        y: 0
        width: root.antiCornerRadius
        height: root.antiCornerRadius * 0.65
        opacity: root.antiCornerRadius > 0 ? 1 : 0
        visible: opacity > 0
        antialiasing: true

        ShapePath {
            fillColor: root.surfaceColor
            strokeColor: "transparent"
            startX: antiCornerLeft.width
            startY: 0
            PathLine {
                x: antiCornerLeft.width
                y: antiCornerLeft.height
            }
            PathCubic {
                x: 0; y: 0
                control1X: antiCornerLeft.width * 0.45
                control1Y: antiCornerLeft.height
                control2X: 0
                control2Y: antiCornerLeft.height * 0.3
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }
        Behavior on width {
            NumberAnimation { duration: 360; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: 360; easing.type: Easing.OutCubic }
        }
    }

    Shape {
        id: antiCornerRight

        x: root.width
        y: 0
        width: root.antiCornerRadius
        height: root.antiCornerRadius * 0.65
        opacity: root.antiCornerRadius > 0 ? 1 : 0
        visible: opacity > 0
        antialiasing: true

        ShapePath {
            fillColor: root.surfaceColor
            strokeColor: "transparent"
            startX: 0
            startY: 0
            PathLine {
                x: 0
                y: antiCornerRight.height
            }
            PathCubic {
                x: antiCornerRight.width; y: 0
                control1X: antiCornerRight.width * 0.55
                control1Y: antiCornerRight.height
                control2X: antiCornerRight.width
                control2Y: antiCornerRight.height * 0.3
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }
        Behavior on width {
            NumberAnimation { duration: 360; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: 360; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        id: shadow

        anchors.fill: bodyShape
        anchors.topMargin: 8
        radius: root.bottomRadius
        color: "#000000"
        opacity: 0
        scale: 1

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: outerGlow

        anchors.fill: bodyShape
        anchors.margins: -1
        radius: root.bottomRadius + 1
        color: "transparent"
        border.width: 1
        border.color: "#000000"
        opacity: 0
    }

    Item {
        id: bodyShape

        anchors.fill: parent
        clip: true

        Rectangle {
            z: 1
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: Math.ceil(parent.height / 2)
            color: root.surfaceColor
        }

        Rectangle {
            z: 0
            anchors.fill: parent
            radius: root.bottomRadius
            color: root.surfaceColor
        }

        Rectangle {
            id: coldSheen

            x: parent.width * 0.08
            y: 3
            width: parent.width * 0.84
            height: Math.max(6, parent.height * 0.32)
            radius: height / 2
            opacity: 0

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: "#00243a00"
                }

                GradientStop {
                    position: 0.34
                    color: "#55d7ff"
                }

                GradientStop {
                    position: 0.68
                    color: "#d6fbff"
                }

                GradientStop {
                    position: 1
                    color: "#00243a00"
                }
            }
        }

        Rectangle {
            id: leftCore

            width: root.expanded ? 84 : 42
            height: width
            radius: width / 2
            x: -width * 0.38
            y: -width * 0.18
            color: "#000000"
            opacity: 0
        }

        Rectangle {
            id: rightCore

            width: root.expanded ? 96 : 48
            height: width
            radius: width / 2
            x: parent.width - width * 0.58
            y: parent.height - width * 0.68
            color: "#000000"
            opacity: 0
        }

        IslandContent {
            id: islandContent

            z: 10
            anchors.fill: parent
            anchors.margins: root.expanded ? 12 * (1 - root.volumeMorph) : 0
            volumeMorph: root.volumeMorph
            volumeKind: root.volumeKind
            mode: root.mode
            handleStyle: root.handleStyle
            appName: root.appName
            title: root.title
            body: root.body
            artist: root.artist
            volume: root.volume
            muted: root.muted
            playing: root.playing
            artUrl: root.artUrl
            mediaAvailable: root.mediaAvailable
            fontFamily: root.fontFamily
            timeText: root.timeText
            dateText: root.dateText
            weatherIcon: root.weatherIcon
            weatherTemp: root.weatherTemp
            weatherAvailable: root.weatherAvailable
            showTimeInIdle: root.showTimeInIdle
            batteryPercent: root.batteryPercent
            batteryCharging: root.batteryCharging
            mediaPosition: root.mediaPosition
            mediaLength: root.mediaLength
            normalizedMediaPosition: root.normalizedMediaPosition
            shuffleActive: root.shuffleActive
            mediaLiked: root.mediaLiked
            timerText: root.timerText
            timerRunning: root.timerRunning
            timerHours: root.timerHours
            timerMinutes: root.timerMinutes
            timerProgress: root.timerProgress

            onMediaTogglePlayingClicked: root.mediaTogglePlayingClicked()
            onMediaNextClicked: root.mediaNextClicked()
            onMediaPreviousClicked: root.mediaPreviousClicked()
            onMediaSeekRequested: function(pos) { root.mediaSeekRequested(pos); }
            onMediaShuffleClicked: root.mediaShuffleClicked()
            onMediaLikeClicked: root.mediaLikeClicked()
            onSettingsClicked: root.settingsClicked()
            onToggleIdleTimeClicked: root.toggleIdleTimeClicked()
            onSmallModeToggled: root.smallModeToggled()
            onTimerHoursAdjust: function(delta) { root.timerHoursAdjust(delta); }
            onTimerMinutesAdjust: function(delta) { root.timerMinutesAdjust(delta); }
            onTimerStartClicked: root.timerStartClicked()
            onTimerResetClicked: root.timerResetClicked()
        }
    }

    Rectangle {
        id: timerEdge

        visible: root.timerRunning
        z: 20
        anchors.fill: parent
        color: "transparent"

        property real smoothProgress: root.timerProgress

        Behavior on smoothProgress {
            NumberAnimation {
                duration: 120
                easing.type: Easing.Linear
            }
        }

        readonly property real stroke: 3
        readonly property real inset: stroke / 2
        readonly property real r: Math.max(2, Math.min(root.bottomRadius, (height - inset) / 2, (width - 2 * inset) / 2))
        readonly property real leftX: inset
        readonly property real rightX: width - inset
        readonly property real topY: 0
        readonly property real bottomY: height - inset
        readonly property real sideLen: Math.max(0, bottomY - r - topY)
        readonly property real bottomLen: Math.max(0, rightX - leftX - 2 * r)
        readonly property real arcLen: Math.PI * r / 2
        readonly property real pathLen: 2 * sideLen + bottomLen + 2 * arcLen
        readonly property real drawn: pathLen * Math.max(0, Math.min(1, smoothProgress))

        Shape {
            anchors.fill: parent
            antialiasing: true

            ShapePath {
                strokeWidth: timerEdge.stroke
                strokeColor: "#ff8a1a"
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                strokeStyle: ShapePath.DashLine
                dashPattern: [Math.max(0.01, timerEdge.drawn), timerEdge.pathLen + 1]

                startX: timerEdge.leftX
                startY: timerEdge.topY

                PathLine {
                    x: timerEdge.leftX
                    y: timerEdge.bottomY - timerEdge.r
                }
                PathArc {
                    x: timerEdge.leftX + timerEdge.r
                    y: timerEdge.bottomY
                    radiusX: timerEdge.r
                    radiusY: timerEdge.r
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: timerEdge.rightX - timerEdge.r
                    y: timerEdge.bottomY
                }
                PathArc {
                    x: timerEdge.rightX
                    y: timerEdge.bottomY - timerEdge.r
                    radiusX: timerEdge.r
                    radiusY: timerEdge.r
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: timerEdge.rightX
                    y: timerEdge.topY
                }
            }
        }
    }

    height: root.targetH

    state: root.mode !== "idle" ? root.mode : "collapsed"

    states: [
        State {
            name: "collapsed"

            PropertyChanges {
                root.width: root.targetW
                root.volumeMorph: 0
            }
        },
        State {
            name: "expanded"

            PropertyChanges {
                root.width: root.targetW
                root.volumeMorph: 0
            }
        },
        State {
            name: "settings"

            PropertyChanges {
                root.width: root.targetW
                root.volumeMorph: 0
            }
        },
        State {
            name: "timer"

            PropertyChanges {
                root.width: root.targetW
                root.volumeMorph: 0
            }
        },
        State {
            name: "notify"

            PropertyChanges {
                root.width: root.targetW
                root.volumeMorph: 0
            }
        },
        State {
            name: "volume"

            PropertyChanges {
                root.width: root.targetW
                root.volumeMorph: 1
            }
        }
    ]

    transitions: [
        Transition {
            to: "volume"

            ParallelAnimation {
                NumberAnimation {
                    property: "width"
                    duration: 400
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.9
                }

                NumberAnimation {
                    property: "volumeMorph"
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
        },
        Transition {
            from: "volume"

            ParallelAnimation {
                NumberAnimation {
                    property: "width"
                    duration: 300
                    easing.type: Easing.InOutCubic
                }

                NumberAnimation {
                    property: "volumeMorph"
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        },
        Transition {
            NumberAnimation {
                property: "width"
                duration: 360
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                property: "volumeMorph"
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    ]

    Behavior on width {
        NumberAnimation {
            duration: 360
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 300
            easing.type: root.mode === "volume" ? Easing.OutBack : Easing.OutCubic
            easing.overshoot: 0.9
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: 360
            easing.type: Easing.OutCubic
        }
    }
}
