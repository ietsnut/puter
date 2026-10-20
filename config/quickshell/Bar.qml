import QtQuick
import Quickshell
import Quickshell.Wayland

// The bottom bar, on the bottom edge: a strip one module tall with the search
// square standing two modules tall in the left corner, open windows right after it,
// and the date and time in the right corner with the settings square beside.
PanelWindow {
    id: bar

    signal search
    signal settings

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

    // The strip's top edge: a 1px line in the outline colour, drawn over the
    // top pixel of the strip and its tabs so nothing moves off the grid. The
    // search square is ink already, so the line starts beside it.
    Rectangle {
        x: searchButton.width
        y: Theme.module
        z: 1
        width: bar.width - x
        height: 1
        color: Theme.outline
    }

    SearchButton {
        id: searchButton
        onClicked: bar.search()
    }

    // Windows sit flush, side by side, straight after the search square: each
    // tab three to eight modules wide, the app's icon in its first module, a
    // 1px line between one tab and the next.
    Row {
        x: Theme.module * 2
        y: Theme.module
        spacing: 0

        Repeater {
            model: ToplevelManager.toplevels

            Chip {
                required property var modelData
                text: modelData.title
                icon: Quickshell.iconPath(DesktopEntries.heuristicLookup(modelData.appId)?.icon ?? "", true)
                minModules: 3
                maxModules: 8
                hoverable: true
                divider: true
                fill: modelData.activated ? Theme.title : Theme.muted
                ink: modelData.activated ? Theme.titleForeground : Theme.mutedForeground
                onClicked: modelData.activate()
            }
        }
    }

    SettingsButton {
        anchors.right: time.left
        y: Theme.module
        onClicked: bar.settings()
    }

    Chip {
        id: time
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
