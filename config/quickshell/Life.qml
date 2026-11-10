import QtQuick
import Quickshell
import Quickshell.Wayland

// The screensaver: after fifteen minutes with no input (the compositor says
// so, ext-idle-notify; nothing here counts), Conway's life fills the screen
// on the desk's colour, in cells half a module square. Each cell is one of
// four colours; a cell that's born takes the colour most of its three
// parents have (a tie goes to the first parent found), and each colour's
// cells are drawn as one blob (Pixels.qml), so living clumps merge. When
// the board settles into stillness or a two-step blink, or empties, it's
// sown afresh. Any input and it's gone.
PanelWindow {
    id: life

    readonly property int cell: Theme.module / 2
    readonly property int columns: Math.ceil(width / cell)
    readonly property int lines: Math.ceil(height / cell)
    readonly property var inks: [Colors.life1, Colors.life2, Colors.life3, Colors.life4]

    // The board: one number a cell, 0 for none, 1 to 4 for a colour; and
    // the one before it, to see it settle.
    property var board: []
    property var last: []

    // Shown from `qs ipc call screensaver start` too, for a look.
    property bool forced: false
    readonly property bool on: idle.isIdle || forced

    function sow() {
        const next = [];
        for (let i = 0; i < columns * lines; i++)
            next.push(Math.random() < 0.3 ? 1 + Math.floor(Math.random() * 4) : 0);
        last = [];
        board = next;
    }

    function tick() {
        const w = columns, h = lines, old = board, next = new Array(w * h).fill(0);
        let alive = 0;
        for (let y = 0; y < h; y++)
            for (let x = 0; x < w; x++) {
                const counts = [0, 0, 0, 0, 0];
                let n = 0;
                for (let dy = -1; dy <= 1; dy++)
                    for (let dx = -1; dx <= 1; dx++) {
                        if (!dx && !dy)
                            continue;
                        // The board wraps round at its edges.
                        const c = old[((y + dy + h) % h) * w + (x + dx + w) % w];
                        if (c) {
                            n++;
                            counts[c]++;
                        }
                    }
                const here = old[y * w + x];
                if (here && (n === 2 || n === 3))
                    next[y * w + x] = here;
                else if (!here && n === 3)
                    next[y * w + x] = counts.indexOf(Math.max(...counts));
                if (next[y * w + x])
                    alive++;
            }
        const same = (a, b) => a.length === b.length && a.every((v, i) => v === b[i]);
        if (alive === 0 || same(next, old) || same(next, last)) {
            sow();
            return;
        }
        last = old;
        board = next;
    }

    // One colour's cells as Pixels rows.
    function rows(color) {
        const out = [];
        for (let y = 0; y < lines; y++) {
            let row = "";
            for (let x = 0; x < columns; x++)
                row += board[y * columns + x] === color ? "#" : ".";
            out.push(row);
        }
        return out;
    }

    IdleMonitor {
        id: idle
        timeout: 15 * 60
    }

    onOnChanged: {
        if (on)
            sow();
        else
            forced = false;
    }

    visible: on || fade.running
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "puter-life"
    WlrLayershell.keyboardFocus: on ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Colors.desk
        opacity: life.on ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                id: fade
                duration: Theme.open * 3
                easing.type: Easing.InOutQuad
            }
        }

        Repeater {
            model: life.on ? 4 : 0

            Pixels {
                required property int index
                cell: life.cell
                ink: life.inks[index]
                rows: life.board.length ? life.rows(index + 1) : []
            }
        }

        Timer {
            running: life.on
            repeat: true
            interval: 160
            onTriggered: life.tick()
        }

        // Input while it's up (forced; the compositor's idle ends by itself):
        // a key, a click or the pointer moving, from a second after it
        // shows, so the pointer arriving over it doesn't count.
        Timer {
            id: armed
            interval: 1000
            running: life.on
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: if (!armed.running) life.forced = false
            onPressed: life.forced = false
        }
        focus: true
        Keys.onPressed: life.forced = false
    }
}
