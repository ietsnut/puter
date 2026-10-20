import QtQuick
import Quickshell
import Quickshell.Wayland

// While a panel is open, an invisible layer over the desk, windows and bar
// (under the panel) catches a click anywhere else and closes it.
PanelWindow {
    id: dismiss

    signal clicked

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: dismiss.clicked()
    }
}
