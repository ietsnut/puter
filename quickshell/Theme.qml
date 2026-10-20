pragma Singleton
import QtQuick
import Quickshell

// The one geometry and a closed palette of three: black, gray and white.
// Anything that needs a fourth tone dithers two of them (the desk, from
// desk.png). Nothing in the shell states a size or colour of its own.
Singleton {
    readonly property int module: 30
    readonly property int inset: 8
    readonly property string font: "Geist"
    readonly property int textSize: 15

    readonly property color black: "#000000"
    readonly property color gray: "#808080"
    readonly property color white: "#ffffff"

    // Roles. Everything else reads these.
    readonly property color background: white
    readonly property color foreground: black
    readonly property color primary: black
    readonly property color primaryForeground: white
    readonly property color muted: gray
    readonly property color mutedForeground: black
}
