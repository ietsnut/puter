import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// The lock screen (the bar's lock button, or `qs ipc call lock lock`): the
// desk's brown, the fly in its middle, and under it a square for each
// number typed of the code. Return tries it; a wrong one flashes the
// squares and clears them. The code is numbers only, set the first time:
// "Choose a code", then "Again". It's the compositor's own lock
// (ext-session-lock): nothing else takes input till it's open. bin/puter-lock
// keeps the code (hashed, on this machine only) and a marker, so a shell
// restarted while locked locks again.
Scope {
    id: root

    readonly property string helper: Quickshell.shellDir + "/../../bin/puter-lock"

    // "choose" and "again" while setting the code, "enter" after.
    property string phase: "enter"
    property string code: ""
    property string first: ""
    property bool hasCode: false
    property bool checking: false
    property bool wrong: false

    function lock() {
        if (sessionLock.locked)
            return;
        code = "";
        first = "";
        wrong = false;
        phase = hasCode ? "enter" : "choose";
        sessionLock.locked = true;
        Quickshell.execDetached([helper, "mark", "on"]);
    }

    function unlock() {
        code = "";
        sessionLock.locked = false;
        Quickshell.execDetached([helper, "mark", "off"]);
    }

    function type(digit) {
        if (checking || code.length >= 32)
            return;
        wrong = false;
        code += digit;
    }

    function submit() {
        if (checking || code === "")
            return;
        if (phase === "choose") {
            first = code;
            code = "";
            phase = "again";
        } else if (phase === "again") {
            if (code !== first) {
                first = "";
                phase = "choose";
                miss();
                return;
            }
            run(setter, code);
            code = "";
        } else {
            run(checker, code);
        }
    }

    function miss() {
        wrong = true;
        code = "";
        flash.restart();
    }

    // A code goes to the helper on its stdin, never on its command line.
    function run(process, value) {
        checking = true;
        process.value = value;
        process.running = true;
    }

    Process {
        id: checker
        property string value
        command: [root.helper, "check"]
        stdinEnabled: true
        onStarted: {
            write(value + "\n");
            stdinEnabled = false;
        }
        onExited: code => {
            stdinEnabled = true;
            value = "";
            root.checking = false;
            if (code === 0)
                root.unlock();
            else
                root.miss();
        }
    }

    Process {
        id: setter
        property string value
        command: [root.helper, "set"]
        stdinEnabled: true
        onStarted: {
            write(value + "\n");
            stdinEnabled = false;
        }
        onExited: code => {
            stdinEnabled = true;
            value = "";
            root.checking = false;
            root.first = "";
            if (code === 0) {
                root.hasCode = true;
                root.phase = "enter";
            } else {
                root.phase = "choose";
                root.miss();
            }
        }
    }

    // Is there a code yet; and was the screen locked when the shell stopped.
    Process {
        id: has
        running: true
        command: [root.helper, "has"]
        onExited: code => {
            root.hasCode = code === 0;
            marked.running = true;
        }
    }

    Process {
        id: marked
        command: [root.helper, "marked"]
        onExited: code => {
            if (code === 0)
                root.lock();
        }
    }

    Timer {
        id: flash
        interval: 600
        onTriggered: root.wrong = false
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            color: Colors.desk

            Item {
                anchors.fill: parent
                focus: true

                Keys.onPressed: event => {
                    if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9)
                        root.type(String(event.key - Qt.Key_0));
                    else if (event.key === Qt.Key_Backspace)
                        root.code = root.code.slice(0, -1);
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        root.submit();
                    else if (event.key === Qt.Key_Escape) {
                        // Before there's a code, Escape gives up locking.
                        if (!root.hasCode)
                            root.unlock();
                        else
                            root.code = "";
                    } else
                        return;
                    event.accepted = true;
                }

                // The fly, where the desk's beetle sits, a module's half a pixel.
                Pixels {
                    id: fly
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -Theme.module
                    cell: Theme.module / 2
                    ink: Colors.mark
                    rows: [
                        ".#...#....#...#.",
                        "..#..##..##..#..",
                        "..#....##....#..",
                        "...#..####..#...",
                        "##....####....##",
                        "..#.#.####.#.#..",
                        "...##.####.##...",
                        "...##.####.##...",
                        "..###......###..",
                        ".#.##.####.##.#.",
                        "#.###......###.#",
                        "###.#.####.#.###",
                        "##.##......##.##",
                        "#.#.#.####.#.#.#",
                        ".####..##..####.",
                        "..##........##.."
                    ]
                }

                // While choosing the code, what to do.
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: fly.y + fly.height + Theme.module
                    height: Theme.module
                    verticalAlignment: Text.AlignVCenter
                    visible: root.phase !== "enter"
                    text: root.phase === "choose" ? "Choose a code" : "Again"
                    color: Colors.mark
                    font.family: Theme.font
                    font.pixelSize: Theme.textSize
                    renderType: Text.CurveRendering
                }

                // A square for each number typed (half a module, half a
                // module apart), in the attention colour when it's wrong; an
                // empty one framed before any.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: fly.y + fly.height + Theme.module * (root.phase === "enter" ? 1 : 2) + Theme.module / 4
                    spacing: Theme.module / 2

                    Repeater {
                        model: Math.max(1, root.code.length)

                        Rectangle {
                            required property int index
                            readonly property bool empty: root.code.length === 0
                            width: Theme.module / 2
                            height: Theme.module / 2
                            radius: Theme.radius / 2
                            color: empty ? "transparent" : root.checking ? Colors.mutedInk : Colors.mark
                            border.width: empty ? 1 : 0
                            border.color: root.wrong ? Colors.attention : Colors.mark
                        }
                    }
                }
            }
        }
    }
}
