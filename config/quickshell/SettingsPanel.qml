import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

// Settings: the network, volume and the computer's activity, one module per
// row and fourteen modules wide, standing on the bar in the right
// corner above its button. Levels are dot matrices (DotMatrix.qml).
PanelWindow {
    id: panel

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int level: sink && sink.audio && !sink.audio.muted ? Math.round(sink.audio.volume * 10) : 0

    function toggle() {
        visible = !visible;
    }

    visible: false
    anchors {
        bottom: true
        right: true
    }
    margins.bottom: Theme.module
    implicitWidth: Theme.module * 14
    implicitHeight: rows.height
    exclusionMode: ExclusionMode.Ignore
    color: Theme.background
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onVisibleChanged: {
        if (visible)
            network.refresh();
    }

    PwObjectTracker {
        objects: [panel.sink]
    }

    // The processor's load over the last minute: a sample every two seconds,
    // thirty of them, from /proc/stat (the share of time not idle), taken
    // only while the panel is open, so the shell does nothing when idle.
    QtObject {
        id: activity

        property var samples: []
        property real busy: 0
        property real total: 0

        function read(text) {
            const fields = text.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const total = fields.reduce((a, b) => a + b, 0);
            const busy = total - fields[3] - (fields[4] || 0);
            if (activity.total) {
                const share = (busy - activity.busy) / Math.max(1, total - activity.total);
                activity.samples = activity.samples.concat([share]).slice(-30);
            }
            activity.busy = busy;
            activity.total = total;
        }
    }

    // Read in place (no process started), every two seconds.
    FileView {
        id: stat
        path: "/proc/stat"
        blockLoading: true
    }

    Timer {
        interval: 2000
        running: panel.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            activity.read(stat.text());
        }
    }

    // The network, from NetworkManager.
    QtObject {
        id: network

        property string connection: ""
        property bool hasWifi: false
        property bool wifiOn: false
        property var networks: []

        function refresh() {
            devices.running = true;
            radio.running = true;
            scan.running = true;
        }

        function run(command) {
            Quickshell.execDetached(command);
            later.restart();
        }
    }

    Timer {
        id: later
        interval: 1500
        onTriggered: network.refresh()
    }

    Process {
        id: devices
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                let connection = "";
                let wifi = false;
                for (const line of text.trim().split("\n")) {
                    const [type, state, name] = line.split(":");
                    if (type === "wifi")
                        wifi = true;
                    if (state === "connected" && !connection)
                        connection = type === "ethernet" ? "Wired" : name;
                }
                network.connection = connection;
                network.hasWifi = wifi;
            }
        }
    }

    Process {
        id: radio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: network.wifiOn = text.trim() === "enabled"
        }
    }

    Process {
        id: scan
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SSID", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const list = [];
                for (const line of text.trim().split("\n")) {
                    const inUse = line.startsWith("*");
                    const rest = line.slice(line.indexOf(":") + 1);
                    const signal = parseInt(rest);
                    const ssid = rest.slice(rest.indexOf(":") + 1).replace(/\\:/g, ":");
                    if (!ssid || seen[ssid])
                        continue;
                    seen[ssid] = true;
                    list.push({ ssid: ssid, active: inUse, signal: signal });
                }
                network.networks = list.slice(0, 6);
            }
        }
    }

    Column {
        id: rows
        width: parent.width

        // Network: what you're on, and Wi-Fi on or off.
        Item {
            width: parent.width
            height: Theme.module

            Label {
                text: "Network"
            }

            Label {
                x: Theme.module * 4 + Theme.inset
                text: network.connection || "Offline"
                color: network.connection ? Theme.foreground : Theme.mutedForeground
            }

            Chip {
                visible: network.hasWifi
                anchors.right: parent.right
                minModules: 3
                hoverable: true
                text: network.wifiOn ? "Wi-Fi on" : "Wi-Fi off"
                fill: network.wifiOn ? Theme.primary : Theme.muted
                ink: network.wifiOn ? Theme.primaryForeground : Theme.mutedForeground
                onClicked: network.run(["nmcli", "radio", "wifi", network.wifiOn ? "off" : "on"])
            }
        }

        // Wi-Fi networks in range; the one you're on in the accent. Each
        // shows its signal in its last module: three columns of dots, one to
        // three of them lit.
        Repeater {
            model: network.wifiOn ? network.networks : []

            Chip {
                id: wifi
                required property var modelData
                readonly property int bars: modelData.signal > 66 ? 3 : modelData.signal > 33 ? 2 : 1
                width: rows.width
                hoverable: true
                text: modelData.ssid
                fill: modelData.active ? Theme.primary : Theme.background
                ink: modelData.active ? Theme.primaryForeground : Theme.foreground
                onClicked: network.run(["nmcli", "device", "wifi", "connect", modelData.ssid])

                DotMatrix {
                    anchors.right: parent.right
                    columns: [1, 2, 3].map(h => h <= wifi.bars ? h : 0)
                    on: wifi.modelData.active ? Theme.primaryForeground : Theme.foreground
                }
            }
        }

        // Volume in ten steps, one module each: a step that's on is a square
        // one inset in (as an app's is), one that's off a dot.
        Item {
            width: parent.width
            height: Theme.module

            Label {
                text: "Volume"
            }

            DotMatrix {
                x: Theme.module * 4
                rows: 1
                cell: Theme.module
                dot: Theme.module - 2 * Theme.inset
                columns: Array.from({ length: 10 }, (_, i) => i < panel.level ? 1 : 0)
            }

            Row {
                x: Theme.module * 4

                Repeater {
                    model: 10

                    Item {
                        required property int index
                        width: Theme.module
                        height: Theme.module

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!panel.sink)
                                    return;
                                panel.sink.audio.muted = false;
                                panel.sink.audio.volume = (index + 1) / 10;
                            }
                        }
                    }
                }
            }
        }

        // Activity: the processor's load over the last minute, newest on the
        // right, three dots to a column, three columns to a module.
        Item {
            width: parent.width
            height: Theme.module

            Label {
                text: "Activity"
            }

            DotMatrix {
                x: Theme.module * 4
                columns: Array.from({ length: 30 }, (_, i) => {
                    const sample = activity.samples[activity.samples.length - 30 + i];
                    return sample === undefined ? 0 : Math.max(sample > 0.02 ? 1 : 0, Math.round(sample * 3));
                })
            }
        }

    }

    Outline {}
}
