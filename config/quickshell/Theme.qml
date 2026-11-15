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
    // Motion: quick for what slides (search's highlight, the switcher's
    // cards), a little longer for what opens. Hovers don't fade: they're
    // instant.
    readonly property int quick: 120
    readonly property int open: 260

    // The nearest module line to a position: what's centred on
    // the screen still stands on the grid.
    function snap(v: real): real {
        return Math.round(v / module) * module;
    }

    // A fill bright enough that what's on it is black (the hover lime, the
    // accent, attention, a bright app colour): text and glyphs on it go dark.
    function bright(c: color): bool {
        return c.a > 0.5 && 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b > 0.5;
    }

    // The ink for text on a fill: black on a bright one, the palette's
    // otherwise.
    function inkOn(c: color, otherwise: color): color {
        return bright(c) ? Colors.buttonHoverInk : otherwise;
    }
}
