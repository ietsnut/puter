import QtQuick
import Quickshell
import Quickshell.Widgets

// A one-module square in the bar's colours holding a 16px glyph from puter's
// icons (IBM's Carbon, theme/icons.map); the hover colour under the pointer.
Rectangle {
    id: button

    // An icon name in puter's theme.
    property string icon: ""
    // Its colour at rest: the bar's, or whatever it stands on.
    property color fill: Theme.bar
    signal clicked
    signal scrolled(int steps)

    width: Theme.module
    height: Theme.module
    color: mouse.containsMouse ? Theme.hover : fill

    IconImage {
        x: (Theme.module - width) / 2
        y: (Theme.module - height) / 2
        implicitSize: 16
        source: Quickshell.iconPath(button.icon)
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()
        onWheel: wheel => button.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
