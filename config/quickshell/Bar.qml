import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Services.Pipewire

// The bar floats over the bottom two modules, a gap off every edge, as
// three pieces: the gear at the left (search), the open windows in a pill
// right beside it, and the network, volume, the date and time, updates,
// restart and shut down in a pill at the right. The desk shows between them,
// and clicks there reach the windows behind.
PanelWindow {
    id: bar

    signal search
    signal update
    signal volume

    // Each agent window's state, by its title: working, waiting or done (set
    // by the agents' hooks over IPC, shell.qml).
    property var agents: ({})

    function setAgent(title, state) {
        const next = Object.assign({}, agents);
        if (state)
            next[title] = state;
        else
            delete next[title];
        agents = next;
    }

    // The update's state (Updates.qml): running, restart, or nothing.
    property string updates: ""

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: !sink || !sink.audio || sink.audio.muted || sink.audio.volume === 0
    property bool online: false

    // Search opened another way still turns the gear.
    function turn() {
        gear.turn();
    }

    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: Theme.module * 2
    // Up to the pills' tops: windows keep the gap from them (labwc's
    // <gap>), as from every edge.
    exclusiveZone: Theme.gap + Theme.bar
    color: "transparent"

    mask: Region {
        item: gear

        Region {
            item: windows
        }
        Region {
            item: status
        }
    }

    Gear {
        id: gear
        x: Theme.gap
        y: Theme.gap
        onClicked: bar.search()
    }

    // The windows, each a tab inside the pill: its app's dot and its title,
    // the focused one on paper.
    Rectangle {
        id: windows
        visible: tabs.count > 0
        x: gear.x + gear.width + Theme.gap
        y: Theme.gap
        width: row.implicitWidth + (Theme.bar - Theme.module)
        height: Theme.bar
        radius: Theme.radius
        color: Colors.bar
        Behavior on width {
            NumberAnimation {
                duration: Theme.open
                easing.type: Easing.OutCubic
            }
        }

        Row {
            id: row
            x: (Theme.bar - Theme.module) / 2
            y: (Theme.bar - Theme.module) / 2
            spacing: 0

            Repeater {
                id: tabs
                model: ToplevelManager.toplevels

                Chip {
                    id: tab
                    required property var modelData
                    // An agent's state (bar.agents): its glyph at the tab's end,
                    // and the whole tab in the attention colour while it waits
                    // for you. "done" shows until you've been to the window.
                    readonly property string agent: bar.agents[modelData.title] ?? ""
                    readonly property bool waiting: agent === "waiting"
                    text: modelData.title
                    // The app's icon from its desktop file, or, without one, the
                    // icon named after the app (as labwc does for its title bar).
                    icon: Quickshell.iconPath(DesktopEntries.heuristicLookup(modelData.appId)?.icon ?? modelData.appId, true)
                    badge: agent && !(agent === "done" && modelData.activated) ? Quickshell.iconPath("puter-agent-" + agent) : ""
                    minModules: 3
                    maxModules: 8
                    hoverable: true
                    fill: waiting ? Colors.attention : modelData.activated ? Colors.tabActive : Colors.tab
                    ink: waiting ? Colors.attentionInk : modelData.activated ? Colors.tabActiveInk : Colors.tabInk
                    onClicked: modelData.activate()

                    Connections {
                        target: tab.modelData

                        function onActivatedChanged() {
                            if (!tab.modelData.activated && tab.agent === "done")
                                bar.setAgent(tab.modelData.title, "");
                        }
                    }
                }
            }
        }
    }

    // The right pill: its buttons and the clock side by side, a gap's half
    // in from its ends, as the windows sit in theirs. A tab on its left with
    // a chevron folds it away off the screen's right edge, leaving only the
    // tab there, flush with the edge; the tab brings it back, its chevron
    // turning to point the way the pill will go.
    property bool folded: false

    Item {
        id: status
        y: Theme.gap
        width: fold.width + pill.width
        height: Theme.bar
        x: bar.folded ? bar.width - fold.width : bar.width - width - Theme.gap
        Behavior on x {
            NumberAnimation {
                duration: Theme.open
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: fold
            width: Theme.gap * 2
            height: Theme.bar
            // Rounded on the left; flush against the pill, or the screen's
            // edge when folded, on the right.
            topLeftRadius: Theme.radius
            bottomLeftRadius: Theme.radius
            color: foldMouse.containsMouse ? Colors.buttonHover : Colors.bar
            Behavior on color {
                ColorAnimation {
                    duration: Theme.quick
                }
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: Quickshell.iconPath("puter-fold")
                rotation: bar.folded ? 180 : 0
                Behavior on rotation {
                    NumberAnimation {
                        duration: Theme.open
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                id: foldMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: bar.folded = !bar.folded
            }
        }

        Rectangle {
            id: pill
            x: fold.width
            width: statusRow.implicitWidth + (Theme.bar - Theme.module)
            height: Theme.bar
            topRightRadius: Theme.radius
            bottomRightRadius: Theme.radius
            color: Colors.bar

            Row {
                id: statusRow
                x: (Theme.bar - Theme.module) / 2
                y: (Theme.bar - Theme.module) / 2

                // The network: signal bars, struck through when offline; opens
                // nmtui in the terminal (networks, Wi-Fi and its passwords).
                BarButton {
                    icon: bar.online ? "puter-network" : "puter-network-off"
                    onClicked: Quickshell.execDetached(["qterminal", "-e", "nmtui"])
                }

                // Volume: a speaker, muted or not; a click opens its slider
                // (Volume.qml), the wheel turns it up or down a tenth at a time.
                BarButton {
                    icon: bar.muted ? "puter-volume-muted" : "puter-volume"
                    onClicked: bar.volume()
                    onScrolled: steps => {
                        if (!bar.sink?.audio)
                            return;
                        bar.sink.audio.muted = false;
                        bar.sink.audio.volume = Math.max(0, Math.min(1, Math.round(bar.sink.audio.volume * 10 + steps) / 10));
                    }
                }

                Chip {
                    text: Qt.formatDateTime(clock.date, "dddd d MMMM HH:mm")
                    fill: Colors.bar
                    ink: Colors.barInk
                }

                // Updates (Updates.qml): the glyph turns while one runs, and the
                // button takes the attention colour when it wants a restart.
                BarButton {
                    icon: bar.updates === "running" ? "puter-agent-working" : "puter-update"
                    fill: bar.updates === "restart" ? Colors.attention : Colors.bar
                    onClicked: bar.update()
                }

                BarButton {
                    icon: "puter-restart"
                    onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                }

                BarButton {
                    icon: "puter-power"
                    onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                }
            }
        }
    }

    // The clock ticks once a minute.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
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
}
