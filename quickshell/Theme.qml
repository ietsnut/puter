pragma Singleton
import QtQuick
import Quickshell

// The one geometry, and the colour roles from Colors.qml (written by
// theme/make from the palette). Nothing in the shell states a size or colour
// of its own.
Singleton {
    readonly property int module: 30
    readonly property int inset: 8
    readonly property string font: "Geist"
    readonly property int textSize: 15

    readonly property color desk: Colors.desk
    readonly property color background: Colors.paper
    readonly property color foreground: Colors.ink
    readonly property color primary: Colors.accent
    readonly property color primaryForeground: Colors.accentInk
    readonly property color muted: Colors.muted
    readonly property color mutedForeground: Colors.mutedInk
}
