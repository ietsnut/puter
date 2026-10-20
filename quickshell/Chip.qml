import QtQuick

// The atom: a flat fill one module tall and a whole number of modules wide,
// so both its edges sit on the grid. Its label starts one inset from the left.
Rectangle {
    id: chip

    property alias text: label.text
    property color fill: Theme.muted
    property color ink: Theme.mutedForeground
    property int minModules: 1
    property int maxModules: 64
    signal clicked

    readonly property int modules: Math.ceil((label.implicitWidth + Theme.inset * 2) / Theme.module)

    color: fill
    implicitHeight: Theme.module
    width: Math.max(minModules, Math.min(maxModules, modules)) * Theme.module

    Text {
        id: label
        x: Theme.inset
        width: chip.width - Theme.inset * 2
        anchors.verticalCenter: parent.verticalCenter
        color: chip.ink
        elide: Text.ElideRight
        font.family: Theme.font
        renderType: Text.CurveRendering
        font.pixelSize: Theme.textSize
    }

    MouseArea {
        anchors.fill: parent
        onClicked: chip.clicked()
    }
}
