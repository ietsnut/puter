import QtQuick
import Quickshell
import Quickshell.Wayland

// The bottom bar: one module tall, one module in from the edges. Open windows
// on the left, the time on the right.
PanelWindow {
    anchors {
        bottom: true
        left: true
        right: true
    }
    margins {
        bottom: Theme.module
        left: Theme.module
        right: Theme.module
    }
    implicitHeight: Theme.module
    color: "transparent"

    Row {
        spacing: 0

        Chip {
            text: "Terminal"
            fill: Theme.foreground
            ink: Theme.background
            onClicked: Quickshell.execDetached(["ghostty"])
        }

        Item {
            width: Theme.module
            height: Theme.module
        }

        // Windows sit side by side, parted by a seam of desk.
        Row {
            spacing: 2

            Repeater {
                model: ToplevelManager.toplevels

                Chip {
                    required property var modelData
                    text: modelData.title
                    maxWidth: Theme.module * 8
                    fill: modelData.activated ? Theme.primary : Theme.muted
                    ink: modelData.activated ? Theme.primaryForeground : Theme.mutedForeground
                    onClicked: modelData.activate()
                }
            }
        }
    }

    Chip {
        anchors.right: parent.right
        text: Qt.formatDateTime(clock.date, "dddd d MMMM HH:mm")
        fill: Theme.background
        ink: Theme.foreground
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
