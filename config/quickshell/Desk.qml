import QtQuick
import Quickshell
import Quickshell.Wayland

// The desk behind every window: one plain colour, with a dot at every module
// corner in desk-dot (the same colour as the desk in palettes without dots).
// The dots are one module's image, tiled: no full-screen picture to keep.
PanelWindow {
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    color: Theme.desk

    // A 2px dot on the corner, the pixel either side of the line, so one
    // module's tile is a pixel in each corner.
    Image {
        anchors.fill: parent
        visible: Theme.deskDot !== Theme.desk
        fillMode: Image.Tile
        // Tiles start at the screen's corner (they're centred otherwise).
        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop
        smooth: false
        source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='30' height='30'>"
            + ["0 0", "29 0", "0 29", "29 29"].map(p => `<rect x='${p.split(" ")[0]}' y='${p.split(" ")[1]}' width='1' height='1' fill='${Theme.deskDot}'/>`).join("")
            + "</svg>"
    }
}
