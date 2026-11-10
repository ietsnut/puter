import QtQuick
import Quickshell
import Quickshell.Wayland

// The screensaver: after fifteen minutes with no input (the compositor says
// so, ext-idle-notify; nothing here counts), Conway's life fills the screen
// on the desk's colour, in cells half a module square, a generation every
// half second. Each cell is one of four colours; a cell that's born takes
// the colour most of its three parents have (a tie goes to the first parent
// found), and each colour's cells are drawn blobby, exactly as Pixels.qml
// draws: a corner with no neighbour round it is rounded half a cell, and an
// empty corner between two neighbours (or two cells touching only there)
// is filled in round, so diagonal steps join by a neck. When the board
// settles into stillness or a two-step blink, or empties, it's sown afresh.
// Each generation (and each sowing) morphs from the last as the desk's bug
// does: the cells that change flip a few at a time, in a random order, over
// most of the half second, the blobs melting from one shape to the next.
// It comes and goes cell by cell, in a scatter, life going on all the
// while: the desk's colour and the life on it cover the screen a few cells
// at a time, and any input uncovers it the same way.
//
// It's painted on a canvas, and each time only the cells that changed and
// their neighbours (whose corners they round) are painted again; the state
// lives in plain JavaScript (`game`), out of QML's properties, for speed.
PanelWindow {
    id: life

    readonly property int cell: Theme.module / 2
    readonly property var inks: [Colors.desk, Colors.life1, Colors.life2, Colors.life3, Colors.life4]

    // Shown from `qs ipc call screensaver start` too, for a look.
    property bool forced: false
    readonly property bool on: idle.isIdle || forced
    // Coming or going: "in", "out", or "" when it's whole or gone.
    property string moving: ""

    // A second and a half either way, by the clock: a slow machine takes
    // fewer, bigger steps.
    readonly property int span: 1500
    // A generation every half second, and the morph to it in 0.4.
    readonly property int generation: 500
    readonly property int morph: 400
    // A morph is under way.
    property bool morphing: false

    // w by h cells; board: 0 for none, 1 to 4 for a colour, and last, the
    // one before, to see it settle; shown: 1 for a cell shown as it comes
    // and goes; dirty: 1 for a cell to paint again, listed in todo; scatter:
    // the cells still to show or hide, in order, null till the first step
    // (when the window has its size), of total, since began. What's drawn
    // is view, which morphs to board: flips, the cells still to flip, in
    // order, of count since t0.
    property var game: ({ w: 0, h: 0 })

    function fresh() {
        const w = Math.ceil(width / cell), h = Math.ceil(height / cell), n = w * h;
        game = {
            w, h,
            board: new Uint8Array(n),
            last: new Uint8Array(n),
            next: new Uint8Array(n),
            shown: new Uint8Array(n),
            dirty: new Uint8Array(n),
            todo: [],
            wipe: true,
            scatter: null,
            total: 0,
            began: 0,
            view: new Uint8Array(n),
            flips: [],
            count: 0,
            t0: 0
        };
        sow();
    }

    // A cell and its eight neighbours (whose corners it rounds or fills),
    // to paint again.
    function touch(g, i) {
        const w = g.w, x = i % w, n = g.dirty.length;
        for (const j of [i - w, i, i + w])
            for (const k of [x > 0 ? j - 1 : -1, j, x < w - 1 ? j + 1 : -1])
                if (k >= 0 && k < n && !g.dirty[k]) {
                    g.dirty[k] = 1;
                    g.todo.push(k);
                }
    }

    function sow() {
        const g = game, b = g.board;
        for (let i = 0; i < b.length; i++)
            b[i] = Math.random() < 0.3 ? 1 + Math.floor(Math.random() * 4) : 0;
        g.last.fill(255);
        begin();
    }

    // The morph to this board: the cells drawn otherwise, shuffled, to flip
    // over the next frames.
    function begin() {
        const g = game, flips = [];
        settle();
        for (let i = 0; i < g.board.length; i++)
            if (g.view[i] !== g.board[i])
                flips.push(i);
        for (let i = flips.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            const t = flips[i];
            flips[i] = flips[j];
            flips[j] = t;
        }
        g.flips = flips;
        g.count = flips.length;
        g.t0 = Date.now();
        morphing = flips.length > 0;
    }

    // Flips as many as the clock says (all, to settle it at once).
    function flip(all) {
        const g = game;
        if (!g.flips.length)
            return;
        const due = all ? g.count : Math.ceil(g.count * Math.min(1, (Date.now() - g.t0) / morph));
        const from = g.count - g.flips.length;
        for (let k = from; k < due; k++) {
            const i = g.flips[k - from];
            g.view[i] = g.board[i];
            if (g.shown[i])
                touch(g, i);
        }
        g.flips.splice(0, due - from);
        if (!g.flips.length)
            morphing = false;
        canvas.requestPaint();
    }

    function settle() {
        flip(true);
    }

    function frame() {
        flip(false);
    }

    function tick() {
        const g = game, w = g.w, h = g.h, old = g.board, next = g.next;
        if (!w)
            return;
        settle();
        let alive = 0, still = true, blink = true;
        for (let y = 0; y < h; y++) {
            const up = ((y + h - 1) % h) * w, row = y * w, down = ((y + 1) % h) * w;
            for (let x = 0; x < w; x++) {
                // The board wraps round at its edges.
                const l = (x + w - 1) % w, r = (x + 1) % w;
                const n = (old[up + l] > 0) + (old[up + x] > 0) + (old[up + r] > 0)
                    + (old[row + l] > 0) + (old[row + r] > 0)
                    + (old[down + l] > 0) + (old[down + x] > 0) + (old[down + r] > 0);
                const here = old[row + x];
                let c = 0;
                if (here)
                    c = n === 2 || n === 3 ? here : 0;
                else if (n === 3) {
                    // The colour most of its three parents have.
                    const p = [old[up + l], old[up + x], old[up + r], old[row + l], old[row + r], old[down + l], old[down + x], old[down + r]].filter(v => v);
                    c = p[0] === p[1] || p[0] === p[2] ? p[0] : p[1] === p[2] ? p[1] : p[0];
                }
                next[row + x] = c;
                if (c)
                    alive++;
                if (c !== here)
                    still = false;
                if (c !== g.last[row + x])
                    blink = false;
            }
        }
        if (alive === 0 || still || blink) {
            sow();
            return;
        }
        // Three boards in turn: this, the last, and the next to fill.
        g.next = g.last;
        g.last = old;
        g.board = next;
        begin();
    }

    // A step of coming or going: as many more cells as the clock says.
    function step() {
        if (!width || !height)
            return;
        if (game.w !== Math.ceil(width / cell) || game.h !== Math.ceil(height / cell))
            fresh();
        const g = game, showing = moving === "in" ? 1 : 0;
        if (g.scatter === null) {
            const order = [];
            for (let i = 0; i < g.shown.length; i++)
                if (g.shown[i] !== showing)
                    order.push(i);
            for (let i = order.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                const t = order[i];
                order[i] = order[j];
                order[j] = t;
            }
            g.scatter = order;
            g.total = order.length;
            g.began = Date.now();
        }
        const due = Math.ceil(g.total * Math.min(1, (Date.now() - g.began) / span));
        const from = g.total - g.scatter.length;
        for (let k = from; k < due; k++) {
            const i = g.scatter[k - from];
            g.shown[i] = showing;
            touch(g, i);
        }
        g.scatter.splice(0, due - from);
        canvas.requestPaint();
        if (g.scatter.length === 0)
            moving = "";
    }

    IdleMonitor {
        id: idle
        timeout: 15 * 60
    }

    onOnChanged: {
        if (!on)
            forced = false;
        // From nothing, a new board; coming back while going, it turns
        // round where it is.
        if (on && moving !== "out")
            game = { w: 0, h: 0 };
        else
            game.scatter = null;
        moving = on ? "in" : "out";
    }

    visible: on || moving !== ""
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

    Item {
        anchors.fill: parent

        Canvas {
            id: canvas
            anchors.fill: parent

            onPaint: {
                const g = life.game;
                if (!g.w)
                    return;
                const ctx = getContext("2d");
                const w = g.w, h = g.h, c = life.cell, r = c / 2, PI = Math.PI;
                const board = g.view, shown = g.shown, todo = g.todo;
                if (g.wipe) {
                    ctx.clearRect(0, 0, width, height);
                    g.wipe = false;
                }
                g.todo = [];
                for (const i of todo)
                    g.dirty[i] = 0;
                // What's at a cell for a layer: 0 the desk's colour, on every
                // shown cell (off the screen counts as shown, so its corners
                // stay square); 1 to 4 a colour's cells, shown.
                const at = (x, y) => x < 0 || y < 0 || x >= w || y >= h ? -1 : y * w + x;
                const has = (layer, j) => layer === 0 ? j < 0 || shown[j] === 1 : j >= 0 && shown[j] === 1 && board[j] === layer;
                // The shape of a cell for a layer: whole (a plain square,
                // drawn at once), or edged (round corners or fillets, drawn
                // with the rest of its layer's).
                const edged = [[], [], [], [], []];
                const desk = String(life.inks[0]);
                ctx.fillStyle = desk;
                for (const i of todo) {
                    const x = i % w, y = (i - x) / w, X = x * c, Y = y * c;
                    const j = [at(x - 1, y), at(x, y - 1), at(x + 1, y), at(x, y + 1)];
                    if (shown[i] && has(0, j[0]) && has(0, j[1]) && has(0, j[2]) && has(0, j[3]))
                        ctx.fillRect(X, Y, c, c);
                    else {
                        ctx.clearRect(X, Y, c, c);
                        edged[0].push(i);
                    }
                    if (!shown[i])
                        continue;
                    // A colour's cells, and the fillets of the colours
                    // round it.
                    for (let layer = 1; layer < 5; layer++)
                        if (has(layer, i) || has(layer, j[0]) || has(layer, j[2]))
                            edged[layer].push(i);
                }
                for (let layer = 0; layer < 5; layer++) {
                    if (!edged[layer].length)
                        continue;
                    ctx.beginPath();
                    for (const i of edged[layer]) {
                        const x = i % w, y = (i - x) / w, X = x * c, Y = y * c;
                        const left = has(layer, at(x - 1, y)), up = has(layer, at(x, y - 1));
                        const right = has(layer, at(x + 1, y)), down = has(layer, at(x, y + 1));
                        if (has(layer, i)) {
                            // The cell, its corners with nothing round them
                            // (beside or across) rounded.
                            const tl = !left && !up && !has(layer, at(x - 1, y - 1));
                            const tr = !right && !up && !has(layer, at(x + 1, y - 1));
                            const br = !right && !down && !has(layer, at(x + 1, y + 1));
                            const bl = !left && !down && !has(layer, at(x - 1, y + 1));
                            if (!tl && !tr && !br && !bl) {
                                ctx.rect(X, Y, c, c);
                                continue;
                            }
                            ctx.moveTo(X + (tl ? r : 0), Y);
                            ctx.lineTo(X + c - (tr ? r : 0), Y);
                            if (tr)
                                ctx.quadraticCurveTo(X + c, Y, X + c, Y + r);
                            ctx.lineTo(X + c, Y + c - (br ? r : 0));
                            if (br)
                                ctx.quadraticCurveTo(X + c, Y + c, X + c - r, Y + c);
                            ctx.lineTo(X + (bl ? r : 0), Y + c);
                            if (bl)
                                ctx.quadraticCurveTo(X, Y + c, X, Y + c - r);
                            ctx.lineTo(X, Y + (tl ? r : 0));
                            if (tl)
                                ctx.quadraticCurveTo(X, Y, X + r, Y);
                            ctx.closePath();
                        } else {
                            // Not this layer's: each corner between two of
                            // its cells filled in, a curve from half a cell
                            // along one side to half along the other.
                            const corners = [[0, 0, left && up], [1, 0, right && up], [1, 1, right && down], [0, 1, left && down]];
                            for (const [sx, sy, fill] of corners) {
                                if (!fill)
                                    continue;
                                const px = X + sx * c, py = Y + sy * c;
                                ctx.moveTo(px, py);
                                ctx.lineTo(X + r, py);
                                ctx.quadraticCurveTo(px, py, px, Y + r);
                                ctx.closePath();
                            }
                        }
                    }
                    ctx.fillStyle = String(life.inks[layer]);
                    ctx.fill();
                }
            }
        }

        // A generation every half second, coming and going too.
        Timer {
            running: life.visible
            repeat: true
            interval: life.generation
            onTriggered: life.tick()
        }

        // Frames, while it comes or goes, or morphs.
        Timer {
            running: life.moving !== "" || life.morphing
            repeat: true
            interval: 33
            onTriggered: {
                if (life.moving !== "")
                    life.step();
                life.frame();
            }
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
