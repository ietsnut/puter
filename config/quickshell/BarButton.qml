import QtQuick

// A one-module square in the bar's colours holding a glyph, drawn as the
// window buttons are (2px strokes in the 10 x 10 box from 10 to 20); the
// hover colour under the pointer. The glyph is its children, drawn in ink
// (dim, when what it stands for is off).
Rectangle {
    id: button

    default property alias glyph: box.data
    property bool dim: false
    readonly property color ink: mouse.containsMouse ? Theme.hoverForeground
        : dim ? Theme.mutedForeground : Theme.barForeground
    signal clicked
    signal scrolled(int steps)

    width: Theme.module
    height: Theme.module
    color: mouse.containsMouse ? Theme.hover : Theme.bar

    Item {
        id: box
        anchors.fill: parent
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()
        onWheel: wheel => button.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
