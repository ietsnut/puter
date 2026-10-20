import QtQuick
import Quickshell
import Quickshell.Wayland

// The desk behind every window: one plain colour.
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
}
