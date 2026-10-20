import QtQuick
import Quickshell
import Quickshell.Wayland

// The bottom bar, on the bottom edge: a strip one module tall with the search
// square standing two modules tall in the left corner, open windows right after it,
// then the settings square, the date and time, and restart and shut down in
// the right corner.
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
        color: Theme.bar
    }

    // The strip's top edge: a 1px line in bar-edge, drawn over the top pixel
    // of the strip and its tabs so nothing moves off the grid, and left out
    // where the palette gives it the bar's own colour (a dark bar needs none).
    // The search square has its own edge, so the line starts beside it.
    Rectangle {
        visible: Theme.barEdge !== Theme.bar
        x: searchButton.width
        y: Theme.module
        z: 1
        width: bar.width - x
        height: 1
        color: Theme.barEdge
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
                // The app's icon from its desktop file, or, without one, the icon
                // named after the app (as labwc does for its title bar).
                icon: Quickshell.iconPath(DesktopEntries.heuristicLookup(modelData.appId)?.icon ?? modelData.appId, true)
                minModules: 3
                maxModules: 8
                hoverable: true
                divider: true
                fill: modelData.activated ? Theme.tabActive : Theme.tab
                ink: modelData.activated ? Theme.tabActiveForeground : Theme.tabForeground
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
        anchors.right: restart.left
        y: Theme.module
        text: Qt.formatDateTime(clock.date, "dddd d MMMM HH:mm")
        fill: Theme.bar
        ink: Theme.barForeground
    }

    // Power, in the corner.
    Chip {
        id: restart
        anchors.right: shutDown.left
        y: Theme.module
        text: "Restart"
        fill: Theme.bar
        ink: Theme.barForeground
        hoverable: true
        onClicked: Quickshell.execDetached(["systemctl", "reboot"])
    }

    Chip {
        id: shutDown
        anchors.right: parent.right
        y: Theme.module
        text: "Shut down"
        fill: Theme.bar
        ink: Theme.barForeground
        hoverable: true
        onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
