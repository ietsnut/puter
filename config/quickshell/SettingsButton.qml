import QtQuick

// A one-module square in the bar's colours with a sliders glyph and the 1px
// outline inside its edges; the hover colour under the pointer. The glyph: two 2px tracks, each with
// a 4px square knob on it, in the window buttons' 10 x 10 box.
Rectangle {
    id: button

    signal clicked

    readonly property color ink: mouse.containsMouse ? Theme.hoverForeground : Theme.barForeground
    // x, y, width, height inside the 10 x 10 box.
    readonly property var glyph: [[0, 2, 10, 2], [6, 1, 4, 4], [0, 6, 10, 2], [0, 5, 4, 4]]

    width: Theme.module
    height: Theme.module
    color: mouse.containsMouse ? Theme.hover : Theme.bar

    Repeater {
        model: button.glyph

        Rectangle {
            required property var modelData
            x: 10 + modelData[0]
            y: 10 + modelData[1]
            width: modelData[2]
            height: modelData[3]
            color: button.ink
        }
    }

    // Outlined only where the bar is, like the search square.
    Outline {
        visible: Theme.barEdge !== Theme.bar
        edgeBottom: false
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()
    }
}
