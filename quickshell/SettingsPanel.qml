import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

// Settings: the network, volume and power, one module per row and fourteen
// modules wide, standing on the bar in the right corner above its button.
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
        command: ["nmcli", "-t", "-f", "IN-USE,SSID", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const list = [];
                for (const line of text.trim().split("\n")) {
                    const inUse = line.startsWith("*");
                    const ssid = line.slice(line.indexOf(":") + 1).replace(/\\:/g, ":");
                    if (!ssid || seen[ssid])
                        continue;
                    seen[ssid] = true;
                    list.push({ ssid: ssid, active: inUse });
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
                text: network.wifiOn ? "Wi-Fi on" : "Wi-Fi off"
                fill: network.wifiOn ? Theme.primary : Theme.muted
                ink: network.wifiOn ? Theme.primaryForeground : Theme.mutedForeground
                onClicked: network.run(["nmcli", "radio", "wifi", network.wifiOn ? "off" : "on"])
            }
        }

        // Wi-Fi networks in range; the one you're on in the accent.
        Repeater {
            model: network.wifiOn ? network.networks : []

            Chip {
                required property var modelData
                width: rows.width
                text: modelData.ssid
                fill: modelData.active ? Theme.primary : Theme.background
                ink: modelData.active ? Theme.primaryForeground : Theme.foreground
                onClicked: network.run(["nmcli", "device", "wifi", "connect", modelData.ssid])
            }
        }

        // Volume in ten steps, one module each, counted off the grid.
        Item {
            width: parent.width
            height: Theme.module

            Label {
                text: "Volume"
            }

            Row {
                x: Theme.module * 4

                Repeater {
                    model: 10

                    Rectangle {
                        required property int index
                        width: Theme.module
                        height: Theme.module
                        color: index < panel.level ? Theme.primary : Theme.muted

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

        // Power.
        Row {
            Chip {
                text: "Log out"
                fill: Theme.foreground
                ink: Theme.background
                onClicked: Quickshell.execDetached(["labwc", "--exit"])
            }

            Chip {
                text: "Restart"
                fill: Theme.foreground
                ink: Theme.background
                onClicked: Quickshell.execDetached(["systemctl", "reboot"])
            }

            Chip {
                text: "Shut down"
                fill: Theme.foreground
                ink: Theme.background
                onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
            }
        }
    }
}
