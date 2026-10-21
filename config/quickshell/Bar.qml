import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

// The bottom bar, on the bottom edge: a strip one module tall with the search
// square standing two modules tall in the left corner, open windows right after it,
// then the network and volume, the date and time, updates, and restart and
// shut down in the right corner, each a one-module glyph from puter's icons.
PanelWindow {
    id: bar

    signal search
    signal update

    // The update's state (Updates.qml): running, restart, or nothing.
    property string updates: ""

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: !sink || !sink.audio || sink.audio.muted || sink.audio.volume === 0
    property bool online: false

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
    // tab three to eight modules wide, the app's icon in its first module.
    Row {
        x: Theme.module * 2
        y: Theme.module
        spacing: 0

        Repeater {
            model: ToplevelManager.toplevels

            Chip {
                id: tab
                required property var modelData
                // An agent's state (Agents.qml): its glyph in the tab's last
                // module, and the whole tab in the attention colour while it
                // waits for you. "done" shows until you've been to the window.
                readonly property string agent: Agents.states[modelData.title] ?? ""
                readonly property bool waiting: agent === "waiting"
                text: modelData.title
                // The app's icon from its desktop file, or, without one, the icon
                // named after the app (as labwc does for its title bar).
                icon: Quickshell.iconPath(DesktopEntries.heuristicLookup(modelData.appId)?.icon ?? modelData.appId, true)
                badge: agent && !(agent === "done" && modelData.activated) ? Quickshell.iconPath("puter-agent-" + agent) : ""
                minModules: 3
                maxModules: 8
                hoverable: true
                fill: waiting ? Theme.attention : modelData.activated ? Theme.tabActive : Theme.tab
                ink: waiting ? Theme.attentionForeground : modelData.activated ? Theme.tabActiveForeground : Theme.tabForeground
                onClicked: modelData.activate()

                Connections {
                    target: tab.modelData

                    function onActivatedChanged() {
                        if (!tab.modelData.activated && tab.agent === "done")
                            Agents.set(tab.modelData.title, "");
                    }
                }
            }
        }
    }

    PwObjectTracker {
        objects: [bar.sink]
    }

    // Online or not, from NetworkManager: nmcli monitor waits for changes
    // (nothing is polled), and each change asks for the devices' states.
    Process {
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: devices.running = true
        }
    }

    Process {
        id: devices
        running: true
        command: ["nmcli", "-t", "-f", "STATE", "device"]
        stdout: StdioCollector {
            onStreamFinished: bar.online = text.split("\n").some(state => state === "connected")
        }
    }

    // The network: signal bars, struck through when offline; opens nmtui
    // in the terminal (networks, Wi-Fi and its passwords).
    BarButton {
        id: network
        anchors.right: volume.left
        y: Theme.module
        icon: bar.online ? "puter-network" : "puter-network-off"
        onClicked: Quickshell.execDetached(["qterminal", "-e", "nmtui"])
    }

    // Volume: a speaker, muted or not; a click mutes or unmutes, the wheel
    // turns it up or down a tenth at a time.
    BarButton {
        id: volume
        anchors.right: time.left
        y: Theme.module
        icon: bar.muted ? "puter-volume-muted" : "puter-volume"
        onClicked: {
            if (bar.sink?.audio)
                bar.sink.audio.muted = !bar.sink.audio.muted;
        }
        onScrolled: steps => {
            if (!bar.sink?.audio)
                return;
            bar.sink.audio.muted = false;
            bar.sink.audio.volume = Math.max(0, Math.min(1, Math.round(bar.sink.audio.volume * 10 + steps) / 10));
        }
    }

    // The clock ticks once a minute.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Chip {
        id: time
        anchors.right: update.left
        y: Theme.module
        text: Qt.formatDateTime(clock.date, "dddd d MMMM HH:mm")
        fill: Theme.bar
        ink: Theme.barForeground
    }

    // Updates (Updates.qml): the glyph turns while one runs, and the button
    // takes the attention colour when it wants a restart to finish.
    BarButton {
        id: update
        anchors.right: restart.left
        y: Theme.module
        icon: bar.updates === "running" ? "puter-agent-working" : "puter-update"
        fill: bar.updates === "restart" ? Theme.attention : Theme.bar
        onClicked: bar.update()
    }

    // Power, in the corner.
    BarButton {
        id: restart
        anchors.right: shutDown.left
        y: Theme.module
        icon: "puter-restart"
        onClicked: Quickshell.execDetached(["systemctl", "reboot"])
    }

    BarButton {
        id: shutDown
        anchors.right: parent.right
        y: Theme.module
        icon: "puter-power"
        onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
    }
}
