import QtQuick
import Quickshell
import Quickshell.Wayland

// The desk behind every window: gray and white dithered on alternate pixels,
// a 2 x 2 tile repeated at its own size so every pixel lands on the grid.
PanelWindow {
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    color: Theme.gray

    Image {
        anchors.fill: parent
        source: "desk.png"
        fillMode: Image.Tile
        smooth: false
    }
}
