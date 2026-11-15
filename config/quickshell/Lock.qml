import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// The lock screen (the bar's lock button, or `qs ipc call lock lock`): the
// desk's brown, the logic analyzer in white lines as on the desk, and under
// it four light boxes that
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

    // The number pad counts with Num Lock off too (an Apple keyboard has no
    // Num Lock key): its keys are then End, Down and the rest, told from the
    // arrows by the keypad modifier.
    function padDigit(key) {
        switch (key) {
        case Qt.Key_Insert: return 0;
        case Qt.Key_End: return 1;
        case Qt.Key_Down: return 2;
        case Qt.Key_PageDown: return 3;
        case Qt.Key_Left: return 4;
        case Qt.Key_Clear: return 5;
        case Qt.Key_Right: return 6;
        case Qt.Key_Home: return 7;
        case Qt.Key_Up: return 8;
        case Qt.Key_PageUp: return 9;
        }
        return -1;
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
                    else if ((event.modifiers & Qt.KeypadModifier) && root.padDigit(event.key) >= 0)
                        root.type(String(root.padDigit(event.key)));
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

                // The logic analyzer in white lines, as on the desk (board.svg,
                // twenty-four modules tall), and two modules under it the
                // code's boxes. The two together in the middle of what the bar
                // leaves, on the module grid.
                Image {
                    id: board
                    height: Theme.module * 24
                    width: Math.round(height * implicitWidth / Math.max(1, implicitHeight))
                    x: Theme.snap((parent.width - width) / 2)
                    y: Theme.snap((parent.height - Theme.module * 2 - (height + Theme.module * 4)) / 2)
                    source: "board.svg"
                    sourceSize.height: height * 2
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                // Four boxes, two modules square and two gaps apart: ten
                // modules across, centred two modules under the board. In the
                // light ink, a dark dot in each as its number's typed, the
                // attention colour a moment when the code's wrong.
                Row {
                    x: Theme.snap((parent.width - width) / 2)
                    y: board.y + board.height + Theme.module * 2
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
            }
        }
    }
}
