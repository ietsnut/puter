import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// The lock screen (the bar's lock button, or `qs ipc call lock lock`): the
// desk's brown, the fly in its middle, and under it a square for each
// number typed. Return tries the code, 2468 on every puter (it's for keeping
// hands off in a workshop, not a secret); a wrong one flashes the squares
// and clears them. It's the compositor's own lock (ext-session-lock):
// nothing else takes input till it's open. While it's locked the state file
// "locked" says so, so a shell restarted while locked locks again.
Scope {
    id: root

    readonly property string theCode: "2468"
    property string code: ""
    property bool wrong: false

    function lock() {
        if (sessionLock.locked)
            return;
        code = "";
        wrong = false;
        sessionLock.locked = true;
        marker.setText("1\n");
    }

    function unlock() {
        code = "";
        sessionLock.locked = false;
        marker.setText("0\n");
    }

    function type(digit) {
        if (code.length >= 32)
            return;
        wrong = false;
        code += digit;
    }

    function submit() {
        if (code === "")
            return;
        if (code === theCode)
            unlock();
        else
            miss();
    }

    function miss() {
        wrong = true;
        code = "";
        flash.restart();
    }

    FileView {
        id: marker
        path: Quickshell.statePath("locked")
        printErrors: false
        onLoaded: if (text().trim() === "1")
            root.lock()
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
                Component.onCompleted: forceActiveFocus()

                Keys.onPressed: event => {
                    if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9)
                        root.type(String(event.key - Qt.Key_0));
                    else if (event.key === Qt.Key_Backspace)
                        root.code = root.code.slice(0, -1);
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        root.submit();
                    else if (event.key === Qt.Key_Escape)
                        root.code = "";
                    else
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

                // A square for each number typed (half a module, half a
                // module apart), in the attention colour when it's wrong; an
                // empty one framed before any.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: fly.y + fly.height + Theme.module + Theme.module / 4
                    spacing: Theme.module / 2

                    Repeater {
                        model: Math.max(1, root.code.length)

                        Rectangle {
                            required property int index
                            readonly property bool empty: root.code.length === 0
                            width: Theme.module / 2
                            height: Theme.module / 2
                            radius: Theme.radius / 2
                            color: empty ? "transparent" : Colors.mark
                            border.width: empty ? 1 : 0
                            border.color: root.wrong ? Colors.attention : Colors.mark
                        }
                    }
                }

                // A click anywhere gives the keys back to the code.
                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.forceActiveFocus()
                }

                // For now, till the lock's proven: a way out in the bottom
                // right corner, where the bar's power button sits. Take it
                // out once locking works every time.
                BarButton {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Theme.gap + (Theme.bar - Theme.module) / 2
                    icon: "window-close"
                    onClicked: root.unlock()
                }
            }
        }
    }
}
