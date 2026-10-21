import QtQuick
import Quickshell.Widgets

// The atom: a flat fill one module tall and a whole number of modules wide,
// so both its edges sit on the grid. Its label starts one inset from the left,
// or, with an icon, the icon is centred in the first module and the label
// starts at the second.
Rectangle {
    id: chip

    property alias text: label.text
    // An icon path (from Quickshell.iconPath); empty for none.
    property string icon: ""
    // A 16px glyph (an icon path) in a module of its own at the right end.
    property string badge: ""
    property color fill: Colors.muted
    property color ink: Colors.mutedInk
    // Chips you can click light up under the pointer, like the window buttons.
    property bool hoverable: false
    property color hoverFill: Colors.buttonHover
    property color hoverInk: Colors.buttonHoverInk
    // A 1px line in the outline colour down the right edge, inside the chip,
    // where chips stand side by side.
    property bool divider: false
    property int minModules: 1
    property int maxModules: 64
    signal clicked

    readonly property int lead: icon ? Theme.module : Theme.inset
    readonly property int tail: badge ? Theme.module : 0
    readonly property int modules: Math.ceil((lead + label.implicitWidth + Theme.inset) / Theme.module) + (badge ? 1 : 0)

    color: hoverable && mouse.containsMouse ? hoverFill : fill
    implicitHeight: Theme.module
    width: Math.max(minModules, Math.min(maxModules, modules)) * Theme.module

    // At 24px, as labwc draws an app's icon on its title bar: an app's square
    // (14px in its 24px icon) then lands one inset in, as on the title bar.
    IconImage {
        visible: chip.icon !== ""
        source: chip.icon
        x: (Theme.module - width) / 2
        y: (Theme.module - height) / 2
        implicitSize: 24
    }

    IconImage {
        visible: chip.badge !== ""
        source: chip.badge
        x: chip.width - Theme.module + (Theme.module - width) / 2
        y: (Theme.module - height) / 2
        implicitSize: 16
    }

    Text {
        id: label
        x: chip.lead
        width: chip.width - chip.lead - chip.tail - Theme.inset
        anchors.verticalCenter: parent.verticalCenter
        color: chip.hoverable && mouse.containsMouse ? chip.hoverInk : chip.ink
        elide: Text.ElideRight
        font.family: Theme.font
        renderType: Text.CurveRendering
        font.pixelSize: Theme.textSize
    }

    Rectangle {
        visible: chip.divider
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Colors.outline
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: chip.hoverable
        onClicked: chip.clicked()
    }
}
