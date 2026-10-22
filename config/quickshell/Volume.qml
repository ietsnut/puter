import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

// Volume: the bar's speaker opens it, standing on the strip in the right
// corner, twelve modules wide and one tall: the speaker (a click mutes or
// unmutes), the level as a bar filling with the accent colour (a click or a
// drag sets it, the wheel turns it a tenth at a time), and the level in
// percent.
PanelWindow {
    id: panel

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: !sink || !sink.audio || sink.audio.muted || sink.audio.volume === 0
    readonly property real level: sink?.audio ? Math.min(1, sink.audio.volume) : 0

    function toggle() {
        visible = !visible;
    }

    function setLevel(value) {
        if (!sink?.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    visible: false
    anchors {
        bottom: true
        right: true
    }
    margins.bottom: Theme.module
    implicitWidth: Theme.module * 12
    implicitHeight: Theme.module
    exclusionMode: ExclusionMode.Ignore
    color: Colors.paper
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "puter-volume"

    PwObjectTracker {
        objects: [panel.sink]
    }

    BarButton {
        id: speaker
        fill: "transparent"
        icon: panel.muted ? "puter-volume-muted" : "puter-volume"
        onClicked: {
            if (panel.sink?.audio)
                panel.sink.audio.muted = !panel.sink.audio.muted;
        }
    }

    // The level: the accent from the left as far as it goes, in whole
    // pixels; dimmed while muted.
    Item {
        id: track
        anchors.left: speaker.right
        anchors.right: percent.left
        height: Theme.module

        Rectangle {
            width: Math.round(track.width * panel.level)
            height: parent.height
            color: panel.muted ? Colors.muted : Colors.accent
        }

        MouseArea {
            anchors.fill: parent
            onPressed: mouse => panel.setLevel(mouse.x / track.width)
            onPositionChanged: mouse => {
                if (pressed)
                    panel.setLevel(mouse.x / track.width);
            }
            onWheel: wheel => panel.setLevel(Math.round(panel.level * 10 + (wheel.angleDelta.y > 0 ? 1 : -1)) / 10)
        }
    }

    Item {
        id: percent
        anchors.right: parent.right
        width: Theme.module * 2
        height: Theme.module

        Label {
            anchors.right: parent.right
            anchors.rightMargin: Theme.inset
            text: Math.round(panel.level * 100) + "%"
            color: panel.muted ? Colors.mutedInk : Colors.ink
        }
    }

    Outline {}
}
