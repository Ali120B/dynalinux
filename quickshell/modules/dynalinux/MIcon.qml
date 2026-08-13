import QtQuick

// Material Symbols Rounded helper.
// Usage:
//   MIcon { name: "battery_full"; size: 14; color: "white" }
//   MIcon { name: "mic"; size: 12; filled: true; weight: Font.Bold }
//
// The variable font supports a FILL axis. Qt cannot drive arbitrary variable
// font axes, but the symbol set ships filled variants by appending styleName
// "Filled" via OpenType features, so a Bold/Black weight + the right glyph
// is usually enough. For exact filled glyphs the same name keeps working.
Text {
    id: root

    property string name: ""
    property real size: 14
    property bool filled: false

    text: name
    color: "#f5f5f5"
    font.family: "Material Symbols Rounded"
    font.pixelSize: size
    font.weight: filled ? Font.Bold : Font.Medium
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.QtRendering
    antialiasing: true
}
