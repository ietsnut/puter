import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

// The bottom bar, on the bottom edge: a strip one module tall with the search
// square standing two modules tall in the left corner, open windows right after it,
// then the network and volume, the date and time, and restart and shut down
// in the right corner, each a one-module glyph.
PanelWindow {
    id: bar

    signal search

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
                required property var modelData
                text: modelData.title
                // The app's icon from its desktop file, or, without one, the icon
                // named after the app (as labwc does for its title bar).
                icon: Quickshell.iconPath(DesktopEntries.heuristicLookup(modelData.appId)?.icon ?? modelData.appId, true)
                minModules: 3
                maxModules: 8
                hoverable: true
                fill: modelData.activated ? Theme.tabActive : Theme.tab
                ink: modelData.activated ? Theme.tabActiveForeground : Theme.tabForeground
                onClicked: modelData.activate()
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

    // The network: three bars, dim when offline; opens nmtui in the terminal
    // (networks, Wi-Fi and its passwords).
    BarButton {
        id: network
        anchors.right: volume.left
        y: Theme.module
        dim: !bar.online
        onClicked: Quickshell.execDetached(["qterminal", "-e", "nmtui"])

        Repeater {
            model: [[10, 17, 3], [14, 14, 6], [18, 11, 9]]

            Rectangle {
                required property var modelData
                x: modelData[0]
                y: modelData[1]
                width: 2
                height: modelData[2]
                color: network.ink
            }
        }
    }

    // Volume: a speaker, with its waves unless muted (then dim); a click
    // mutes or unmutes, the wheel turns it up or down a tenth at a time.
    BarButton {
        id: volume
        anchors.right: time.left
        y: Theme.module
        dim: bar.muted
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

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            // The speaker: a 3 x 4 body and its cone, filled.
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: volume.ink
                startX: 10
                startY: 13
                PathLine { x: 13; y: 13 }
                PathLine { x: 16; y: 10 }
                PathLine { x: 16; y: 20 }
                PathLine { x: 13; y: 17 }
                PathLine { x: 10; y: 17 }
                PathLine { x: 10; y: 13 }
            }

            // Its wave.
            ShapePath {
                strokeColor: bar.muted ? "transparent" : volume.ink
                strokeWidth: 2
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap

                PathAngleArc {
                    centerX: 15
                    centerY: 15
                    radiusX: 4
                    radiusY: 4
                    startAngle: -50
                    sweepAngle: 100
                }
            }
        }
    }

    Chip {
        id: time
        anchors.right: restart.left
        y: Theme.module
        text: Qt.formatDateTime(clock.date, "dddd d MMMM HH:mm")
        fill: Theme.bar
        ink: Theme.barForeground
    }

    // Power, in the corner. Restart: a ring with an arrowhead at its open
    // end; shut down: the power sign, a ring open at the top and a bar
    // through the gap.
    BarButton {
        id: restart
        anchors.right: shutDown.left
        y: Theme.module
        onClicked: Quickshell.execDetached(["systemctl", "reboot"])

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: restart.ink
                strokeWidth: 2
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap

                PathAngleArc {
                    centerX: 15
                    centerY: 15
                    radiusX: 4
                    radiusY: 4
                    startAngle: -60
                    sweepAngle: 300
                }
            }

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: restart.ink
                startX: 16
                startY: 9
                PathLine { x: 21; y: 9 }
                PathLine { x: 21; y: 14 }
                PathLine { x: 16; y: 9 }
            }
        }
    }

    BarButton {
        id: shutDown
        anchors.right: parent.right
        y: Theme.module
        onClicked: Quickshell.execDetached(["systemctl", "poweroff"])

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: shutDown.ink
                strokeWidth: 2
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap

                PathAngleArc {
                    centerX: 15
                    centerY: 16
                    radiusX: 4
                    radiusY: 4
                    startAngle: -50
                    sweepAngle: 280
                }
            }
        }

        Rectangle {
            x: 14
            y: 10
            width: 2
            height: 6
            color: shutDown.ink
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
