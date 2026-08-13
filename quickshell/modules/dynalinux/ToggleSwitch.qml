import QtQuick

Item {
    id: root

    property bool checked: false
    signal toggled()

    width: 40
    height: 22

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? "#4a8af4" : "#3a3a3a"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Rectangle {
        width: 18
        height: 18
        radius: 9
        x: root.checked ? root.width - width - 2 : 2
        anchors.verticalCenter: parent.verticalCenter
        color: "#ffffff"
        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
