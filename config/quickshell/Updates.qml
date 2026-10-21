import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

// Updates: everything on puter brought to the newest there is, by
// bin/puter-update (Arch and the kernel, puter's own packages, firmware,
// puter, Claude Code). It stands on the strip in the right
// corner, over the bar's update button, twenty-four modules wide: a title
// strip, then what's out of date, a row each (looked up every time it opens),
// and a row with the button that starts it all (sudo never asks for a
// password on puter: install.sh's access). Once started, the rows give way
// to the updater's output, a line to a module, with a row of progress
// over it filling a module at a time. Closing it leaves the update running; the bar's button shows it.
PanelWindow {
    id: panel

    // checking, ready, running or done.
    property string phase: "ready"
    property var items: []
    property var lines: []
    property int step: 0
    property int steps: 0
    property string stepName: ""
    // How far into the step, from pacman's (12/80) counts.
    property real stepPart: 0
    property var failed: []
    property bool restart: false
    property date started: new Date()
    property date now: new Date()

    readonly property int columns: 24
    // The updater's output: a line to a module, in the same 15px as all text.
    readonly property int outputRows: 12
    readonly property bool output: phase === "running" || phase === "done"
    readonly property int bodyRows: output ? outputRows : phase === "checking" ? 1 : Math.max(1, items.length)
    readonly property real progress: phase === "done" ? 1 : steps > 0 ? (step - 1 + stepPart) / steps : 0
    readonly property string script: Quickshell.shellDir + "/../../bin/puter-update"
    readonly property string minutes: {
        const m = Math.max(1, Math.round((now - started) / 60000));
        return m + (m === 1 ? " minute" : " minutes");
    }
    // For the bar's button: running, restart (to finish) or nothing.
    readonly property string barState: phase === "running" ? "running" : phase === "done" && restart ? "restart" : ""

    function toggle() {
        visible = !visible;
    }

    function check() {
        phase = "checking";
        items = [];
        checker.running = true;
    }

    function start() {
        lines = [];
        failed = [];
        restart = false;
        step = 0;
        steps = 0;
        stepName = "";
        stepPart = 0;
        started = new Date();
        now = started;
        phase = "running";
        updater.running = true;
    }

    // A line of the updater's output: its "::" lines move the progress, the
    // rest is shown (without colour codes, and only what a carriage return
    // left of a line redrawn in place).
    function read(data) {
        const line = data.split("\r").pop().replace(/\x1b\[[0-9;?]*[A-Za-z]/g, "");
        if (line.startsWith("::step ")) {
            const parts = line.split(" ");
            step = Number(parts[1]);
            steps = Number(parts[2]);
            stepName = parts.slice(3).join(" ");
            stepPart = 0;
            return;
        }
        if (line.startsWith("::fail ")) {
            failed = failed.concat([line.slice(7)]);
            return;
        }
        if (line === "::restart") {
            restart = true;
            return;
        }
        if (line === "::done") {
            phase = "done";
            return;
        }
        const count = line.match(/^\((\d+)\/(\d+)\) /);
        if (count)
            stepPart = Math.min(1, Number(count[1]) / Number(count[2]));
        lines = lines.concat([line]).slice(-outputRows);
    }

    // Opening looks again, unless an update is running or has news.
    onVisibleChanged: {
        if (visible && phase !== "running" && phase !== "done")
            check();
    }

    Process {
        id: checker
        command: [panel.script, "check"]
        stdout: StdioCollector {
            onStreamFinished: {
                panel.items = text.split("\n").filter(line => line !== "").map(line => {
                    const [name, detail] = line.split("\t");
                    return { name: name, detail: detail ?? "" };
                });
                if (panel.phase === "checking")
                    panel.phase = "ready";
            }
        }
    }

    Process {
        id: updater
        // -n: were sudo to want a password after all, it fails rather than waits.
        command: ["sudo", "-n", panel.script, "run"]
        stdout: SplitParser {
            onRead: data => panel.read(data)
        }
        stderr: SplitParser {
            onRead: data => panel.read(data)
        }
        onExited: code => {
            panel.phase = "done";
            if (code !== 0 && panel.failed.length === 0 && panel.step === 0)
                panel.failed = ["sudo"];
        }
    }

    // The elapsed minutes.
    Timer {
        running: panel.phase === "running"
        repeat: true
        interval: 30000
        onTriggered: panel.now = new Date()
    }

    visible: false
    anchors {
        bottom: true
        right: true
    }
    margins.bottom: Theme.module
    implicitWidth: Theme.module * columns
    implicitHeight: Theme.module * (1 + bodyRows + (output ? 1 : 0) + 1)
    exclusionMode: ExclusionMode.Ignore
    color: Colors.paper
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "puter-updates"

    // The title strip.
    Rectangle {
        id: strip
        width: parent.width
        height: Theme.module
        color: Colors.title

        IconImage {
            x: (Theme.module - width) / 2
            y: (Theme.module - height) / 2
            implicitSize: 16
            source: Quickshell.iconPath("puter-update")
        }

        Label {
            x: Theme.module
            text: "Updates"
            color: Colors.titleInk
        }

        Label {
            anchors.right: close.left
            anchors.rightMargin: Theme.inset
            color: Colors.mutedInk
            text: panel.phase === "checking" ? "Looking"
                : panel.phase === "ready" ? (panel.items.length === 0 ? "Up to date" : panel.items.length + (panel.items.length === 1 ? " update" : " updates"))
                : panel.phase === "running" ? panel.minutes
                : "Took " + panel.minutes
        }

        BarButton {
            id: close
            anchors.right: parent.right
            fill: "transparent"
            icon: "window-close"
            onClicked: panel.visible = false
        }

        Rectangle {
            y: Theme.module - 1
            width: parent.width
            height: 1
            color: Colors.outline
        }
    }

    // What's out of date: what, then by how much.
    Column {
        visible: !panel.output
        y: Theme.module
        width: parent.width

        Item {
            visible: panel.phase === "checking" || panel.items.length === 0
            width: parent.width
            height: Theme.module

            Label {
                color: Colors.mutedInk
                text: panel.phase === "checking" ? "Looking for updates…" : "Everything is up to date."
            }
        }

        Repeater {
            model: panel.phase === "checking" ? [] : panel.items

            Item {
                required property var modelData
                width: parent.width
                height: Theme.module

                Label {
                    width: Theme.module * 6 - Theme.inset * 2
                    elide: Text.ElideRight
                    text: modelData.name
                }

                Label {
                    x: Theme.module * 6 + Theme.inset
                    width: parent.width - x - Theme.inset
                    elide: Text.ElideRight
                    color: Colors.mutedInk
                    text: modelData.detail
                }
            }
        }
    }

    // The updater's output, its newest lines at the bottom.
    Column {
        visible: panel.output
        y: Theme.module + (panel.outputRows - panel.lines.length) * Theme.module
        x: Theme.inset
        width: parent.width - Theme.inset * 2

        Repeater {
            model: panel.lines

            Text {
                required property var modelData
                width: parent.width
                height: Theme.module
                verticalAlignment: Text.AlignVCenter
                text: modelData
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: modelData.startsWith("!! ") ? Colors.attention : modelData.startsWith("== ") ? Colors.ink : Colors.mutedInk
                font.family: "puter-mono"
                font.pixelSize: Theme.textSize
                font.weight: modelData.startsWith("== ") ? Font.DemiBold : Font.Normal
                renderType: Text.CurveRendering
            }
        }
    }

    // Progress: a module at a time, under the step it's on.
    Rectangle {
        visible: panel.output
        y: Theme.module * (1 + panel.outputRows)
        width: parent.width
        height: Theme.module
        color: Colors.muted

        Rectangle {
            width: Math.round(panel.progress * panel.columns) * Theme.module
            height: Theme.module
            color: panel.phase === "done" && panel.failed.length > 0 ? Colors.attention : Colors.accent
        }

        Label {
            width: parent.width - Theme.inset * 2
            elide: Text.ElideRight
            text: panel.phase === "running" ? (panel.steps > 0 ? panel.step + " of " + panel.steps + " · " + panel.stepName : "Starting")
                : panel.failed.length > 0 ? "Done, except " + panel.failed.join(", ")
                : panel.restart ? "Up to date. Restart to finish." : "Up to date."
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Colors.outline
        }
    }

    // The button, and what it does.
    Item {
        y: parent.height - Theme.module
        width: parent.width
        height: Theme.module

        Label {
            width: parent.width - button.width - Theme.inset * 2
            elide: Text.ElideRight
            color: Colors.mutedInk
            text: panel.output ? "~/.local/state/puter/update.log" : "Arch, firmware, puter, its apps and Claude Code"
        }

        Chip {
            id: button
            anchors.right: parent.right
            minModules: 8
            maxModules: 8
            fill: panel.phase === "running" || panel.phase === "checking" ? Colors.muted : panel.phase === "done" && panel.restart ? Colors.attention : Colors.accent
            ink: panel.phase === "running" || panel.phase === "checking" ? Colors.mutedInk : Colors.accentInk
            hoverable: panel.phase === "ready" || panel.phase === "done"
            text: panel.phase === "running" ? "Updating…"
                : panel.phase === "done" ? (panel.restart ? "Restart" : "Close")
                : "Update everything"
            onClicked: {
                if (panel.phase === "ready")
                    panel.start();
                else if (panel.phase === "done" && panel.restart)
                    Quickshell.execDetached(["systemctl", "reboot"]);
                else if (panel.phase === "done") {
                    panel.phase = "ready";
                    panel.visible = false;
                }
            }

            Rectangle {
                width: 1
                height: parent.height
                color: Colors.outline
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Colors.outline
        }
    }

    // Its edges, but not along the screen's right edge.
    Outline {
        edgeRight: false
    }
}
