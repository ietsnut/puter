import QtQuick
import Quickshell
import Quickshell.Widgets

// A two-module square in the search colour with the magnifier from puter's
// icons (IBM's Carbon) at 32px in its middle; the hover colour under the
// pointer.
Rectangle {
    id: button

    signal clicked

    width: Theme.module * 2
    height: Theme.module * 2
    color: mouse.containsMouse ? Theme.hover : Theme.search

    IconImage {
        x: (button.width - width) / 2
        y: (button.height - height) / 2
        implicitSize: 32
        source: Quickshell.iconPath("puter-search")
    }

    // Outlined only where the bar is (palettes whose bar-edge isn't the
    // bar's own colour); a coloured square stands on the desk without one.
    Outline {
        visible: Theme.barEdge !== Theme.bar
        edgeBottom: false
        edgeLeft: false
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()
    }
}
