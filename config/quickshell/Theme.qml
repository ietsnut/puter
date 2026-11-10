pragma Singleton
import QtQuick
import Quickshell

// The one geometry: the module everything is a whole number of, the inset
// text keeps from an edge, the corner, the gap things float apart by, the
// type and the motion. Colours are Colors.qml's (written by theme/make from
// the palette). Nothing in the shell states a size of its own.
Singleton {
    readonly property int module: 30
    readonly property int inset: 8
    // Every corner: windows, pills, tabs, panels.
    readonly property int radius: 4
    // What floats keeps this far from the screen's edge and from its
    // neighbours: the bar's pills, the gear.
    readonly property int gap: 10
    // The bar's pills and the gear: a module and a gap, standing in the
    // bottom two modules with a gap above and below.
    readonly property int bar: module + gap
    // The palette's font, through the name fontconfig gives it
    // (config/fontconfig/conf.d, from theme/make).
    readonly property string font: "puter-sans"
    readonly property int textSize: 15
    // Search's own type: the query large, as Spotlight sets it.
    readonly property int queryText: 22
    // Motion: quick for hovers, a little longer for what opens.
    readonly property int quick: 120
    readonly property int open: 260
}
