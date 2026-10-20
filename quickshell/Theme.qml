pragma Singleton
import QtQuick
import Quickshell

// Electronaut's tokens: the one geometry and a closed palette. Nothing in the
// shell states a size or colour of its own.
Singleton {
    readonly property int module: 30
    readonly property int inset: 8
    readonly property string font: "Geist"
    readonly property int textSize: 15

    readonly property color background: "#efffe1"
    readonly property color foreground: "#1b322d"
    readonly property color primary: "#cef058"
    readonly property color primaryForeground: "#2f4a00"
    readonly property color secondary: "#94e2d5"
    readonly property color secondaryForeground: "#1b322d"
    readonly property color muted: "#b3cbc5"
    readonly property color mutedForeground: "#28463f"
}
