import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

// Wi-Fi: the bar's network button opens it, standing over the bar's right
// pill, as wide and padded as it (shell.qml sets its width), so its cells
// stand over the bar's buttons. A row each, a module tall and a half gap apart: Wi-Fi and its
// switch; the networks in reach, strongest first (its signal, its name, a
// lock when it has a password, the one you're on in the accent; a click
// joins one, and one whose password isn't known yet opens a row under it to
// type it in); then looking again, and nmtui for the rest (wired networks,
// VPNs, forgetting one).
PanelWindow {
    id: panel

    readonly property int most: 8
    property bool enabled: true
    property bool scanning: false
    property var networks: []
    property var saved: []
    // The network asking for its password, and the one being joined.
    property string asking: ""
    property string joining: ""
    property string error: ""

    function toggle() {
        visible = !visible;
    }

    function scan(rescan) {
        scanning = true;
        lister.command = ["nmcli", "-t", "-e", "no", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", rescan ? "yes" : "auto"];
        lister.running = true;
        savedLister.running = true;
        radio.running = true;
    }

    function join(network) {
        error = "";
        if (network.active)
            return;
        if (network.secure && !saved.includes(network.ssid) && asking !== network.ssid) {
            asking = network.ssid;
            return;
        }
        connect(network.ssid, saved.includes(network.ssid) ? ["nmcli", "--wait", "30", "connection", "up", "id", network.ssid] : ["nmcli", "--wait", "30", "device", "wifi", "connect", network.ssid]);
    }

    function connect(ssid, command) {
        joining = ssid;
        joiner.command = command;
        joiner.running = true;
    }

    onVisibleChanged: {
        asking = "";
        error = "";
        if (visible)
            scan(false);
    }

    visible: false
    anchors {
        bottom: true
        right: true
    }
    margins.bottom: Theme.module * 2
    margins.right: Theme.gap
    implicitHeight: rows.implicitHeight + Theme.gap
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "puter-network"
    WlrLayershell.keyboardFocus: asking ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // The networks in reach: one row per name, at its strongest.
    Process {
        id: lister
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                for (const line of text.split("\n")) {
                    const parts = line.split(":");
                    if (parts.length < 4)
                        continue;
                    const ssid = parts.slice(3).join(":");
                    if (!ssid)
                        continue;
                    const network = { ssid: ssid, active: parts[0] === "*", signal: Number(parts[1]), secure: parts[2] !== "" && parts[2] !== "--" };
                    const was = seen[ssid];
                    if (!was || network.active || (!was.active && network.signal > was.signal))
                        seen[ssid] = Object.assign(network, { active: network.active || (was?.active ?? false) });
                }
                panel.networks = Object.values(seen).sort((a, b) => (b.active - a.active) || (b.signal - a.signal)).slice(0, panel.most);
                panel.scanning = false;
            }
        }
    }

    // The networks NetworkManager knows the password of.
    Process {
        id: savedLister
        command: ["nmcli", "-t", "-e", "no", "-f", "TYPE,NAME", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: panel.saved = text.split("\n").filter(line => line.startsWith("802-11-wireless:")).map(line => line.slice(16))
        }
    }

    Process {
        id: radio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: panel.enabled = text.trim() === "enabled"
        }
    }

    Process {
        id: switcher
        onExited: panel.scan(false)
    }

    Process {
        id: joiner
        stderr: StdioCollector {
            id: joinErrors
        }
        onExited: code => {
            if (code === 0) {
                panel.asking = "";
                panel.error = "";
            } else {
                panel.error = (joinErrors.text.split("\n").find(line => line.trim()) ?? "Couldn't join " + panel.joining).replace(/^Error: /, "");
            }
            panel.joining = "";
            panel.scan(false);
        }
    }

    Card {
        anchors.fill: parent

        // Inside, a half gap in from every edge, as the bar's pill holds its
        // buttons, and a half gap between rows.
        Column {
            id: rows
            spacing: Theme.gap / 2
            x: Theme.gap / 2
            y: Theme.gap / 2
            width: parent.width - Theme.gap

            // Wi-Fi, and its switch: a module-wide track with a cell-sized
            // knob, at the left when off and the right, in the accent, when on.
            Item {
                width: parent.width
                height: Theme.module

                IconImage {
                    x: (Theme.module - width) / 2
                    y: (Theme.module - height) / 2
                    implicitSize: 16
                    source: Quickshell.iconPath(panel.enabled ? "puter-network" : "puter-network-off")
                }

                Label {
                    x: Theme.module
                    text: "Wi-Fi"
                    font.weight: Font.Medium
                }

                Rectangle {
                    id: toggle
                    anchors.right: parent.right
                    width: Theme.module * 2
                    height: Theme.module
                    radius: Theme.radius / 2
                    color: panel.enabled ? Colors.accent : Colors.muted

                    Rectangle {
                        x: panel.enabled ? Theme.module + 4 : 4
                        y: 4
                        width: Theme.module - 8
                        height: Theme.module - 8
                        radius: Theme.radius / 2
                        color: switchMouse.containsMouse ? Colors.buttonHover : Colors.paper
                    }

                    MouseArea {
                        id: switchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            switcher.command = ["nmcli", "radio", "wifi", panel.enabled ? "off" : "on"];
                            switcher.running = true;
                            panel.enabled = !panel.enabled;
                            panel.networks = [];
                        }
                    }
                }
            }

            Item {
                visible: list.count === 0
                width: parent.width
                height: Theme.module

                Label {
                    x: Theme.module
                    color: Colors.mutedInk
                    text: !panel.enabled ? "Wi-Fi is off" : panel.scanning ? "Looking for networks…" : "No networks in reach"
                }
            }

            Repeater {
                id: list
                model: panel.networks

                Column {
                    id: entry
                    required property var modelData
                    readonly property bool active: modelData.active
                    readonly property bool busy: panel.joining === modelData.ssid
                    width: parent.width
                    spacing: Theme.gap / 2

                    Rectangle {
                        id: line
                        width: parent.width
                        height: Theme.module
                        radius: Theme.radius / 2
                        color: row.containsMouse && !entry.active ? Colors.buttonHover : entry.active ? Colors.accent : "transparent"

                        // The signal: the bars, fainter the weaker it is.
                        Glyph {
                            x: (Theme.module - width) / 2
                            y: (Theme.module - height) / 2
                            on: line.color
                            opacity: entry.busy ? 1 : 0.35 + 0.65 * entry.modelData.signal / 100
                            glyph: Quickshell.iconPath(entry.busy ? "puter-agent-working" : "puter-network")
                        }

                        Label {
                            x: Theme.module
                            width: parent.width - x - Theme.module - (status.visible ? status.implicitWidth + Theme.inset : 0)
                            elide: Text.ElideRight
                            text: entry.modelData.ssid
                            color: Theme.inkOn(line.color, Colors.ink)
                            font.weight: entry.active ? Font.Medium : Font.Normal
                        }

                        Label {
                            id: status
                            x: parent.width - Theme.module - implicitWidth
                            visible: entry.active || entry.busy
                            color: Theme.inkOn(line.color, Colors.mutedInk)
                            text: entry.busy ? "Joining" : "Connected"
                        }

                        Glyph {
                            x: parent.width - Theme.module + (Theme.module - width) / 2
                            y: (Theme.module - height) / 2
                            on: line.color
                            visible: entry.modelData.secure
                            glyph: Quickshell.iconPath("puter-locked")
                        }

                        MouseArea {
                            id: row
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: panel.join(entry.modelData)
                        }
                    }

                    // Its password, typed in under it.
                    Rectangle {
                        visible: panel.asking === entry.modelData.ssid
                        width: parent.width
                        height: Theme.module
                        radius: Theme.radius / 2
                        color: Colors.muted

                        TextInput {
                            id: input
                            x: Theme.module
                            width: parent.width - x - join.width - Theme.inset
                            anchors.verticalCenter: parent.verticalCenter
                            clip: true
                            echoMode: TextInput.Password
                            color: Colors.ink
                            selectionColor: Colors.accent
                            selectedTextColor: Colors.accentInk
                            font.family: Theme.font
                            font.pixelSize: Theme.textSize
                            onVisibleChanged: if (visible) {
                                text = "";
                                forceActiveFocus();
                            }
                            Keys.onEscapePressed: panel.asking = ""
                            Keys.onReturnPressed: join.clicked()

                            Text {
                                visible: !input.text
                                text: "Password"
                                color: Colors.mutedInk
                                font: input.font
                            }
                        }

                        Chip {
                            id: join
                            anchors.right: parent.right
                            minModules: 2
                            maxModules: 2
                            hoverable: true
                            fill: Colors.accent
                            ink: Colors.accentInk
                            text: "Join"
                            onClicked: {
                                if (input.text)
                                    panel.connect(entry.modelData.ssid, ["nmcli", "--wait", "30", "device", "wifi", "connect", entry.modelData.ssid, "password", input.text]);
                            }
                        }
                    }
                }
            }

            // What went wrong joining.
            Rectangle {
                visible: panel.error !== ""
                width: parent.width
                height: Theme.module
                radius: Theme.radius / 2
                color: Colors.attention

                Label {
                    x: Theme.module
                    width: parent.width - x - Theme.inset
                    elide: Text.ElideRight
                    color: Colors.attentionInk
                    text: panel.error
                }
            }

            // Looking again, and the rest in nmtui.
            Item {
                width: parent.width
                height: Theme.module

                BarButton {
                    fill: "transparent"
                    icon: panel.scanning ? "puter-agent-working" : "puter-renew"
                    onClicked: panel.scan(true)
                }

                BarButton {
                    anchors.right: parent.right
                    fill: "transparent"
                    icon: "puter-settings"
                    onClicked: {
                        panel.visible = false;
                        Quickshell.execDetached(["qterminal", "-e", "nmtui"]);
                    }
                }
            }
        }
    }
}
