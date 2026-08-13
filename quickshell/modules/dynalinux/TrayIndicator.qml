import QtQuick

// A small floating tray indicator chip or circle.
// Dismissable on click. Reappears when `dismissed` is reset externally.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property real iconSize: 12
    property color iconColor: "#e0e0e0"
    property color backgroundColor: "#000000"
    property color borderColor: "#1a1a1a"
    property bool circular: false
    property bool active: false
    property bool dismissed: false
    readonly property bool showing: active && !dismissed

    signal clicked

    width: chip.width
    height: chip.height
    opacity: showing ? 1 : 0
    visible: opacity > 0
    scale: showing ? 1 : 0.7

    Rectangle {
        id: chip

        width: root.circular ? 18 : (root.label !== "" ? iconItem.width + labelText.contentWidth + 14 : iconItem.width + 10)
        height: 18
        radius: height / 2
        color: chipMouse.containsMouse ? "#0f0f0f" : root.backgroundColor
        border.width: 1
        border.color: root.borderColor

        Row {
            anchors.centerIn: parent
            spacing: 3

            MIcon {
                id: iconItem

                name: root.icon
                size: root.iconSize
                color: root.iconColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: labelText

                text: root.label
                color: root.iconColor
                font.family: "Noto Sans"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                visible: root.label !== "" && !root.circular
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: chipMouse

            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.dismissed = true;
                root.clicked();
            }
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
}
