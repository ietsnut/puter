import QtQuick
import Quickshell.Widgets

// One of puter's glyphs (an icon path), 16px unless told otherwise, in ink:
// light, or black when what it stands on (`on`) is a bright fill (the hover
// lime, the accent, attention), as text on those is. The black one is the
// glyph's "-on-bright" twin, which theme/make draws for every puter-* glyph
// and the window buttons' (the shell draws in software: no recolouring
// effects).
IconImage {
    // The colour behind it.
    property color on: "transparent"
    // The glyph's path, in ink.
    property string glyph: ""

    implicitSize: 16
    source: glyph && Theme.bright(on) ? twin(glyph) : glyph

    // The black twin's path: Quickshell.iconPath gives image://icon/NAME
    // (with any query after it), or a file's path.
    function twin(path) {
        if (/\.svg$/.test(path))
            return path.replace(/\.svg$/, "-on-bright.svg");
        const at = path.indexOf("?");
        return at < 0 ? path + "-on-bright" : path.substring(0, at) + "-on-bright" + path.substring(at);
    }
}
