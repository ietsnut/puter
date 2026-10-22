pragma Singleton
import QtQuick
import Quickshell

// The one geometry: the module everything is a whole number of, the inset
// text keeps from an edge, and the type. Colours are Colors.qml's (written
// by theme/make from the palette). Nothing in the shell states a size of its
// own.
Singleton {
    readonly property int module: 30
    readonly property int inset: 8
    // The palette's font, through the name fontconfig gives it
    // (config/fontconfig/conf.d, from theme/make).
    readonly property string font: "puter-sans"
    readonly property int textSize: 15
}
