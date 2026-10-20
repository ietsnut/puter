import QtQuick

// The atom: a flat fill one module tall and a whole number of modules wide,
// so both its edges sit on the grid. Its label starts one inset from the left.
Rectangle {
    id: chip

    property alias text: label.text
    property color fill: Theme.muted
    property color ink: Theme.mutedForeground
    // Chips you can click light up under the pointer, like the window buttons.
    property bool hoverable: false
    property color hoverFill: Theme.hover
    property color hoverInk: Theme.hoverForeground
    property int minModules: 1
    property int maxModules: 64
    signal clicked

    readonly property int modules: Math.ceil((label.implicitWidth + Theme.inset * 2) / Theme.module)

    color: hoverable && mouse.containsMouse ? hoverFill : fill
    implicitHeight: Theme.module
    width: Math.max(minModules, Math.min(maxModules, modules)) * Theme.module

    Text {
        id: label
        x: Theme.inset
        width: chip.width - Theme.inset * 2
        anchors.verticalCenter: parent.verticalCenter
        color: chip.hoverable && mouse.containsMouse ? chip.hoverInk : chip.ink
        elide: Text.ElideRight
        font.family: Theme.font
        renderType: Text.CurveRendering
        font.pixelSize: Theme.textSize
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: chip.hoverable
        onClicked: chip.clicked()
    }
}
