import QtQuick
import Quickshell
import Quickshell.Wayland

// The bottom bar, on the bottom edge: a strip one module tall with the search
// square standing two modules tall in the left corner, open windows after it,
// and the date and time in the right corner.
PanelWindow {
    id: bar

    signal search

    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: Theme.module * 2
    exclusiveZone: Theme.module
    color: "transparent"

    // Only the strip and the square take clicks; the rest of the top row is
    // the desk, so clicks there reach the windows behind it.
    mask: Region {
        item: strip

        Region {
            item: searchButton
        }
    }

    Rectangle {
        id: strip
        y: Theme.module
        width: bar.width
        height: Theme.module
        color: Theme.background
    }

    SearchButton {
        id: searchButton
        onClicked: bar.search()
    }

    // Windows sit flush, side by side, one module after the search square:
    // each tab three to eight modules wide, parted by a hairline of white.
    Row {
        x: Theme.module * 3
        y: Theme.module
        spacing: 0

        Repeater {
            model: ToplevelManager.toplevels

            Chip {
                required property var modelData
                text: modelData.title
                minModules: 3
                maxModules: 8
                divider: true
                fill: modelData.activated ? Theme.primary : Theme.muted
                ink: modelData.activated ? Theme.primaryForeground : Theme.mutedForeground
                onClicked: modelData.activate()
            }
        }
    }

    Chip {
        anchors.right: parent.right
        y: Theme.module
        text: Qt.formatDateTime(clock.date, "dddd d MMMM HH:mm")
        fill: Theme.background
        ink: Theme.foreground
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
