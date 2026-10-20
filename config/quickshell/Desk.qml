import QtQuick
import Quickshell
import Quickshell.Wayland

// The desk behind every window: one plain colour, with a dot at every module
// corner in desk-dot (the same colour as the desk in palettes without dots).
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

    Canvas {
        anchors.fill: parent
        visible: Theme.deskDot !== Theme.desk
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = Theme.deskDot;
            // A 2px dot on each corner: the pixel either side of the line.
            for (let x = Theme.module; x < width; x += Theme.module)
                for (let y = Theme.module; y < height; y += Theme.module)
                    ctx.fillRect(x - 1, y - 1, 2, 2);
        }
    }
}
