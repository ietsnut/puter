import QtQuick

// A line of text one inset in, centred in its one-module row.
Text {
    x: Theme.inset
    anchors.verticalCenter: parent.verticalCenter
    color: Theme.foreground
    font.family: Theme.font
    font.pixelSize: Theme.textSize
    renderType: Text.CurveRendering
}
