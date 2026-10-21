import QtQuick
import Quickshell
import Quickshell.Widgets

// A square in the bar's colours, a module unless told otherwise, holding a
// glyph from puter's icons (IBM's Carbon, theme/icons.map) in its middle,
// 16px unless told otherwise; the hover colour under the pointer.
Rectangle {
    id: button

    // An icon name in puter's theme.
    property string icon: ""
    // Its colour at rest: the bar's, or whatever it stands on.
    property color fill: Colors.bar
    property int iconSize: 16
    signal clicked
    signal scrolled(int steps)

    width: Theme.module
    height: Theme.module
    color: mouse.containsMouse ? Colors.buttonHover : fill

    IconImage {
        x: (button.width - width) / 2
        y: (button.height - height) / 2
        implicitSize: button.iconSize
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
