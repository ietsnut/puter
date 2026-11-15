import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// The lock screen (the bar's lock button, or `qs ipc call lock lock`): the
// desk's brown, the fly in its middle, and under it four boxes that fill as
// the numbers are typed. The fourth tries the code, 2468 on every puter
// (it's for keeping hands off in a workshop, not a secret); a wrong one
// flashes the boxes and clears them. It's the compositor's own lock
// (ext-session-lock): nothing else takes input till it's open. While it's
// locked the state file "locked" says so, so a shell restarted while locked
// locks again.
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

    // Four numbers: the fourth tries it.
    function type(digit) {
        if (code.length >= theCode.length)
            return;
        wrong = false;
        code += digit;
        if (code.length === theCode.length)
            submit();
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

                // Four boxes, a module square and half a module apart: framed
                // while empty, filled as each number's typed, framed in the
                // attention colour a moment when the code's wrong.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: fly.y + fly.height + Theme.module
                    spacing: Theme.module / 2

                    Repeater {
                        model: root.theCode.length

                        Rectangle {
                            required property int index
                            readonly property bool filled: index < root.code.length
                            width: Theme.module
                            height: Theme.module
                            radius: Theme.radius / 2
                            color: filled ? Colors.mark : "transparent"
                            border.width: 1
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
