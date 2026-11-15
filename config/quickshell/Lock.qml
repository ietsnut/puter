import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// The lock screen (the bar's lock button, or `qs ipc call lock lock`): the
// desk's brown, the fly in its middle, and under it four light boxes that
// take a dot as each number's typed. The fourth tries the code, 2468 on
// every puter (it's for keeping hands off in a workshop, not a secret); a
// wrong one flashes the boxes and clears them. It's the compositor's own lock
// (ext-session-lock): nothing else takes input till it's open. It locks at
// every boot, and while it's locked the state file "locked" says so, so a
// shell restarted while locked locks again.
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

    // Locked from the start of every boot: a marker in the runtime folder
    // (emptied at boot) tells a new session from the shell reloading.
    FileView {
        id: booted
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/puter-booted"
        printErrors: false
        onLoadFailed: {
            setText("1\n");
            root.lock();
        }
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

                // The fly, where the desk's beetle sits (a module's half a
                // pixel, eight modules square), on the module grid.
                Pixels {
                    id: fly
                    x: Theme.snap((parent.width - width) / 2)
                    y: Theme.snap((parent.height - Theme.module * 2 - height) / 2)
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

                // Four boxes, two modules square and two gaps apart: ten
                // modules across, a module wider than the fly each side, and
                // two modules under it. In the light ink, a dark dot in each as
                // its number's typed, the attention colour a moment when the
                // code's wrong.
                Row {
                    x: fly.x + (fly.width - width) / 2
                    y: fly.y + fly.height + Theme.module * 2
                    spacing: Theme.gap * 2

                    Repeater {
                        model: root.theCode.length

                        Rectangle {
                            required property int index
                            width: Theme.module * 2
                            height: Theme.module * 2
                            radius: Theme.radius
                            color: root.wrong ? Colors.attention : Colors.mark

                            Rectangle {
                                visible: parent.index < root.code.length
                                anchors.centerIn: parent
                                width: Theme.module / 2
                                height: Theme.module / 2
                                radius: width / 2
                                color: Colors.desk
                            }
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
