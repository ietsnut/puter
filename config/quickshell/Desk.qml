import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// The desk behind every window: plain brown with the beetle in its middle,
// and ~/Desktop on it, as on a Mac: its folders and files as flat pixel
// icons on a grid filling from the top left, down each column. Click to
// pick one (Ctrl adds, a drag round some picks those), double-click to open
// (a folder in the file manager, a file in its app), drag to move them
// about, onto a folder to put them in it, or out to an app; drop files from
// an app onto it to copy them here. Return renames, as does a click on the
// name of the one picked; Delete (or Ctrl+Backspace) deletes for good,
// after asking: there's no trash. Right-click for the rest. Where each one
// sits is kept (state: desk.json). bin/puter-desk does the file work.
PanelWindow {
    id: desk

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "puter-desk"
    // A click on the desk gives it the keys (to rename, delete, select all).
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: Colors.desk

    readonly property string dir: Quickshell.env("HOME") + "/Desktop"
    readonly property string helper: Quickshell.shellDir + "/../../bin/puter-desk"

    // The grid: a cell four modules square (the icon's tile in the top
    // three, its name in the last), a gap in from the top and left, above
    // the bar.
    readonly property int cellW: Theme.module * 4
    readonly property int cellH: Theme.module * 4
    readonly property int cols: Math.max(1, Math.floor((width - Theme.gap * 2) / cellW))
    readonly property int rows: Math.max(1, Math.floor((height - Theme.module * 2 - Theme.gap) / cellH))
    // The icons' pixels, big ones: 8 across is 64px.
    readonly property real iconCell: Theme.module * 4 / 15
    // The icon's tile: three modules square, a half gap in, centred in
    // the cell's top three modules.
    readonly property real box: Theme.module * 3 - Theme.gap

    // Each name's cell, [column from the left, row from the top].
    property var placed: ({})
    // Which are folders.
    property var folders: ({})
    // Where new ones should land (a drop, a new folder), by name.
    property var pending: ({})
    property var selected: []
    property string renaming: ""
    // Names being renamed, shown as their new ones till the file follows.
    property var renamed: ({})
    // The folder a drag is over.
    property string target: ""
    // The icon a drag was started from, and where on it.
    property var grab: null
    // The rubber band, in the desk's coordinates, and what was picked before.
    property var band: null
    property var before: []
    // A right-click menu: {x, y, items: [{text, run}]}.
    property var menu: null
    // The names waiting to be deleted, once you say so.
    property var asking: []

    function cellX(c) {
        return Theme.gap + c * cellW;
    }
    function cellY(r) {
        return Theme.gap + r * cellH;
    }
    function cellAt(x, y) {
        return [Math.max(0, Math.min(cols - 1, Math.floor((x - Theme.gap) / cellW))), Math.max(0, Math.min(rows - 1, Math.floor((y - Theme.gap) / cellH)))];
    }
    function path(name) {
        return dir + "/" + name;
    }
    function uri(name) {
        return "file://" + path(name).split("/").map(encodeURIComponent).join("/");
    }
    function nameAt(x, y) {
        const c = cellAt(x, y);
        if (x < cellX(c[0]) || x >= cellX(c[0]) + cellW || y < cellY(c[1]) || y >= cellY(c[1]) + cellH)
            return "";
        for (const name in placed)
            if (placed[name][0] === c[0] && placed[name][1] === c[1])
                return name;
        return "";
    }

    // The free cell nearest `want` (or the first free one, down each column
    // from the top left, with no `want`).
    function free(taken, want) {
        const key = (c, r) => c + "," + r;
        if (!want) {
            for (let c = 0; c < cols; c++)
                for (let r = 0; r < rows; r++)
                    if (!taken[key(c, r)])
                        return [c, r];
            return [cols - 1, rows - 1];
        }
        want = [Math.max(0, Math.min(cols - 1, want[0])), Math.max(0, Math.min(rows - 1, want[1]))];
        for (let d = 0; d < cols + rows; d++)
            for (let dc = -d; dc <= d; dc++)
                for (const dr of [d - Math.abs(dc), Math.abs(dc) - d]) {
                    const c = want[0] + dc, r = want[1] + dr;
                    if (c >= 0 && r >= 0 && c < cols && r < rows && !taken[key(c, r)])
                        return [c, r];
                }
        return want;
    }

    // Everything in ~/Desktop a cell: where it was, where it was dropped, or
    // the next free one; kept for next time.
    function relayout() {
        if (!store.ready || files.status !== FolderListModel.Ready)
            return;
        const names = [], dirs = {};
        for (let i = 0; i < files.count; i++) {
            const name = files.get(i, "fileName");
            names.push(name);
            dirs[name] = files.get(i, "fileIsDir");
        }
        const taken = {}, next = {}, saved = spots.cells || {};
        const keep = (name, spot) => {
            taken[spot[0] + "," + spot[1]] = true;
            next[name] = spot;
        };
        const fits = spot => spot && spot[0] < cols && spot[1] < rows && !taken[spot[0] + "," + spot[1]];
        for (const name of names)
            if (!(name in pending) && fits(saved[name]))
                keep(name, saved[name]);
        for (const name of names)
            if (name in pending)
                keep(name, free(taken, pending[name]));
        for (const name of names)
            if (!(name in next))
                keep(name, free(taken, null));
        folders = dirs;
        placed = next;
        const still = {};
        for (const name in pending)
            if (!names.includes(name))
                still[name] = pending[name];
        pending = still;
        selected = selected.filter(name => name in next || name in pending);
        spots.cells = next;
        store.writeAdapter();
    }

    // The helper, one job at a time: [args, done(code, out, err)].
    property var queue: []
    function run(args, done) {
        queue = queue.concat([{ args, done }]);
        if (!worker.running)
            pump();
    }
    function pump() {
        if (queue.length === 0)
            return;
        worker.command = [helper].concat(queue[0].args);
        worker.running = true;
    }
    function say(text) {
        if (text.trim())
            Quickshell.execDetached(["notify-send", "-a", "Desk", "Desk", text.trim()]);
    }

    function open(names) {
        for (const name of names)
            Quickshell.execDetached(["xdg-open", path(name)]);
    }
    function newFolder(spot) {
        run(["new-folder", dir], (code, out, err) => {
            const name = out.trim();
            if (code !== 0 || !name)
                return say(err);
            pending = Object.assign({}, pending, { [name]: spot });
            selected = [name];
            renaming = name;
            relayout();
        });
    }
    function rename(old, name) {
        renaming = "";
        name = name.trim();
        if (!name || name === old)
            return;
        pending = Object.assign({}, pending, { [name]: placed[old] });
        renamed = Object.assign({}, renamed, { [old]: name });
        selected = [name];
        run(["rename", path(old), name], (code, out, err) => {
            const r = Object.assign({}, renamed);
            delete r[old];
            renamed = r;
            if (code !== 0) {
                const p = Object.assign({}, pending);
                delete p[name];
                pending = p;
                selected = [old];
                return say(err);
            }
        });
    }
    function remove(names) {
        asking = [];
        if (names.length === 0)
            return;
        selected = [];
        run(["delete"].concat(names.map(path)), (code, out, err) => {
            if (code !== 0)
                say(err);
        });
    }
    // Everything back on the grid by name, from the top left.
    function cleanUp() {
        spots.cells = {};
        const names = Object.keys(placed).sort((a, b) => a.localeCompare(b));
        const taken = {}, next = {};
        for (const name of names) {
            const spot = free(taken, null);
            taken[spot[0] + "," + spot[1]] = true;
            next[name] = spot;
        }
        spots.cells = next;
        relayout();
    }

    function startDrag(item, name, at) {
        grab = { name, dx: at.x, dy: at.y };
        const names = selected.includes(name) ? selected : [name];
        dragger.Drag.mimeData = {
            "text/uri-list": names.map(uri).join("\r\n") + "\r\n",
            "text/plain": names.map(path).join("\n")
        };
        item.grabToImage(result => {
            dragger.Drag.imageSource = result.url;
            dragger.Drag.hotSpot.x = at.x;
            dragger.Drag.hotSpot.y = at.y;
            dragger.Drag.active = true;
        }, Qt.size(item.width, item.height));
    }
    // Picked icons dropped on the desk: the one dragged lands in the cell
    // under it, the rest keep where they were from it, each in the nearest
    // free cell.
    function reposition(x, y) {
        const anchor = placed[grab.name];
        if (!anchor)
            return;
        const to = cellAt(x - grab.dx + cellW / 2, y - grab.dy + cellH / 2);
        const moving = selected.includes(grab.name) ? [grab.name].concat(selected.filter(n => n !== grab.name)) : [grab.name];
        const taken = {}, next = {};
        for (const name in placed)
            if (!moving.includes(name)) {
                next[name] = placed[name];
                taken[placed[name][0] + "," + placed[name][1]] = true;
            }
        for (const name of moving) {
            const spot = free(taken, [placed[name][0] + to[0] - anchor[0], placed[name][1] + to[1] - anchor[1]]);
            taken[spot[0] + "," + spot[1]] = true;
            next[name] = spot;
        }
        spots.cells = next;
        relayout();
    }

    function openMenu(x, y, items) {
        const w = Theme.module * 6 + Theme.gap, h = items.length * Theme.module + (items.length + 1) * Theme.gap / 2;
        menu = { x: Math.min(x, width - w - Theme.gap), y: Math.min(y, height - Theme.module * 2 - h), items };
    }
    function itemMenu(x, y) {
        const names = selected.slice();
        openMenu(x, y, [
            { text: "Open", run: () => open(names) },
            { text: "Rename", run: () => renaming = names[0], one: true },
            { text: "Delete", run: () => asking = names }
        ].filter(item => !item.one || names.length === 1));
    }
    function deskMenu(x, y) {
        const spot = cellAt(x, y);
        openMenu(x, y, [
            { text: "New Folder", run: () => newFolder(spot) },
            { text: "Clean Up", run: () => cleanUp() },
            { text: "Open in Files", run: () => Quickshell.execDetached(["xdg-open", dir]) }
        ]);
    }

    FolderListModel {
        id: files
        folder: "file://" + desk.dir
        showDirsFirst: false
        showHidden: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
        onStatusChanged: settle.restart()
        onCountChanged: settle.restart()
    }

    Connections {
        target: files
        function onRowsInserted() {
            settle.restart();
        }
        function onRowsRemoved() {
            settle.restart();
        }
        function onDataChanged() {
            settle.restart();
        }
    }

    onWidthChanged: settle.restart()
    onHeightChanged: settle.restart()

    Timer {
        id: settle
        interval: 30
        onTriggered: desk.relayout()
    }

    FileView {
        id: store
        property bool ready: false
        path: Quickshell.statePath("desk.json")
        printErrors: false
        onLoaded: {
            ready = true;
            settle.restart();
        }
        onLoadFailed: {
            ready = true;
            settle.restart();
        }

        JsonAdapter {
            id: spots
            property var cells: ({})
        }
    }

    Process {
        id: worker
        stdout: StdioCollector {
            id: out
        }
        stderr: StdioCollector {
            id: err
        }
        onExited: code => {
            const job = desk.queue[0];
            desk.queue = desk.queue.slice(1);
            if (job && job.done)
                job.done(code, out.text, err.text);
            desk.pump();
        }
    }

    // The beetle, in the middle of what the bar leaves, 16 pixels square
    // drawn blobby (Pixels.qml), a module's half each.
    Pixels {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Theme.module
        cell: Theme.module / 2
        ink: Colors.mark
        rows: [
            "....##....##....",
            "......####......",
            "##...######...##",
            ".#............#.",
            "##..########..##",
            ".##############.",
            "...#........#...",
            "....###..###....",
            ".#.####..####.#.",
            "#..####..####..#",
            "#..####..####..#",
            "...####..#.##...",
            ".#.##.#..#.##.#.",
            ".#..#.#..#.#..#.",
            ".#............#.",
            "..#..........#.."
        ]
    }

    // The keys, while the desk has them.
    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_F2) {
                if (desk.selected.length === 1)
                    desk.renaming = desk.selected[0];
            } else if (event.key === Qt.Key_Delete || ctrl && event.key === Qt.Key_Backspace) {
                if (desk.selected.length)
                    desk.asking = desk.selected.slice();
            } else if (ctrl && event.key === Qt.Key_A) {
                desk.selected = Object.keys(desk.placed);
            } else if (ctrl && event.key === Qt.Key_O) {
                desk.open(desk.selected);
            } else if (ctrl && (event.modifiers & Qt.ShiftModifier) && event.key === Qt.Key_N) {
                desk.newFolder(null);
            } else if (event.key === Qt.Key_Escape) {
                desk.selected = [];
            } else {
                return;
            }
            event.accepted = true;
        }
    }

    // The desk itself: a click picks nothing, a drag draws the band, a
    // right-click its menu.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: mouse => {
            keys.forceActiveFocus();
            desk.menu = null;
            if (mouse.button === Qt.RightButton) {
                desk.selected = [];
                desk.deskMenu(mouse.x, mouse.y);
                return;
            }
            desk.before = mouse.modifiers & Qt.ControlModifier ? desk.selected.slice() : [];
            desk.selected = desk.before;
            desk.band = { x0: mouse.x, y0: mouse.y, x1: mouse.x, y1: mouse.y };
        }
        onPositionChanged: mouse => {
            if (!desk.band)
                return;
            const b = { x0: desk.band.x0, y0: desk.band.y0, x1: mouse.x, y1: mouse.y };
            desk.band = b;
            const left = Math.min(b.x0, b.x1), right = Math.max(b.x0, b.x1);
            const top = Math.min(b.y0, b.y1), bottom = Math.max(b.y0, b.y1);
            const hit = [];
            for (const name in desk.placed) {
                const x = desk.cellX(desk.placed[name][0]) + (desk.cellW - desk.box) / 2;
                const y = desk.cellY(desk.placed[name][1]);
                if (x < right && x + desk.box > left && y < bottom && y + desk.cellH > top)
                    hit.push(name);
            }
            desk.selected = desk.before.concat(hit.filter(n => !desk.before.includes(n)));
        }
        onReleased: desk.band = null
    }

    Rectangle {
        visible: desk.band !== null
        x: desk.band ? Math.min(desk.band.x0, desk.band.x1) : 0
        y: desk.band ? Math.min(desk.band.y0, desk.band.y1) : 0
        width: desk.band ? Math.abs(desk.band.x1 - desk.band.x0) : 0
        height: desk.band ? Math.abs(desk.band.y1 - desk.band.y0) : 0
        radius: Theme.radius / 2
        color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15)
        border.width: 1
        border.color: Colors.accent
    }

    Repeater {
        model: files

        Item {
            id: icon

            required property string fileName
            required property bool fileIsDir
            required property string fileSuffix
            required property url fileUrl

            // Where it sits; a name just made (renamed, dropped) has its spot
            // from the start, so it doesn't blink in.
            readonly property var spot: desk.placed[fileName] ?? desk.pending[fileName]
            readonly property string shown: desk.renamed[fileName] ?? fileName
            readonly property bool chosen: desk.selected.includes(fileName) || desk.selected.includes(shown)
            readonly property bool picture: ["png", "jpg", "jpeg", "gif", "webp", "bmp", "svg"].includes(fileSuffix.toLowerCase())

            visible: spot !== undefined
            x: spot ? desk.cellX(spot[0]) : 0
            y: spot ? desk.cellY(spot[1]) : 0
            width: desk.cellW
            height: desk.cellH

            // The icon, on a dark tile with a 1px frame while picked or while
            // something's dragged over its folder: square, in the cell's top
            // three modules.
            Rectangle {
                id: tile
                x: (desk.cellW - width) / 2
                y: Theme.gap / 2
                width: desk.box
                height: desk.box
                radius: Theme.radius
                color: icon.chosen || desk.target === icon.fileName ? Colors.bar : "transparent"
                border.width: icon.chosen || desk.target === icon.fileName ? 1 : 0
                border.color: desk.target === icon.fileName ? Colors.accent : Colors.frame

                // A flat folder: its tab and its body.
                Pixels {
                    visible: icon.fileIsDir
                    anchors.centerIn: parent
                    cell: desk.iconCell
                    ink: Colors.folder
                    rows: [
                        "###.....",
                        "########",
                        "########",
                        "########",
                        "########",
                        "########"
                    ]
                }

                // A page with its top corner cut.
                Pixels {
                    visible: !icon.fileIsDir && (!icon.picture || thumb.status !== Image.Ready)
                    anchors.centerIn: parent
                    cell: desk.iconCell
                    ink: Colors.mark
                    rows: [
                        "#####..",
                        "######.",
                        "#######",
                        "#######",
                        "#######",
                        "#######",
                        "#######",
                        "#######"
                    ]
                }

                // A picture shows itself.
                Image {
                    id: thumb
                    visible: icon.picture && status === Image.Ready
                    anchors.centerIn: parent
                    width: desk.iconCell * 8
                    height: desk.iconCell * 8
                    source: icon.picture ? icon.fileUrl : ""
                    sourceSize.width: width * 2
                    sourceSize.height: height * 2
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                }
            }

            // Its name, one line in the cell's last module row (shortened in
            // the middle, as on a Mac), on the tile's colour while picked.
            Rectangle {
                visible: desk.renaming !== icon.fileName
                x: (desk.cellW - width) / 2
                y: Theme.module * 3
                width: Math.min(desk.cellW, name.implicitWidth + Theme.inset * 2)
                height: Theme.module
                radius: Theme.radius / 2
                color: icon.chosen ? Colors.bar : "transparent"
                border.width: icon.chosen ? 1 : 0
                border.color: Colors.frame

                Text {
                    id: name
                    anchors.centerIn: parent
                    width: parent.width - Theme.inset * 2
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                    text: icon.shown
                    color: icon.chosen ? Colors.ink : Colors.mark
                    font.family: Theme.font
                    font.pixelSize: Theme.textSize
                    renderType: Text.CurveRendering
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                property point press
                property bool moved: false
                property bool wasChosen: false

                onPressed: m => {
                    keys.forceActiveFocus();
                    desk.menu = null;
                    rename.stop();
                    press = Qt.point(m.x, m.y);
                    moved = false;
                    wasChosen = icon.chosen;
                    if (m.button === Qt.RightButton) {
                        if (!icon.chosen)
                            desk.selected = [icon.fileName];
                        desk.itemMenu(icon.x + m.x, icon.y + m.y);
                    } else if (m.modifiers & Qt.ControlModifier) {
                        desk.selected = icon.chosen ? desk.selected.filter(n => n !== icon.fileName) : desk.selected.concat([icon.fileName]);
                    } else if (!icon.chosen) {
                        desk.selected = [icon.fileName];
                    }
                }
                onPositionChanged: m => {
                    if (moved || !(pressedButtons & Qt.LeftButton) || !icon.chosen)
                        return;
                    if (Math.hypot(m.x - press.x, m.y - press.y) > 6) {
                        moved = true;
                        desk.startDrag(icon, icon.fileName, press);
                    }
                }
                onReleased: m => {
                    if (moved || m.button !== Qt.LeftButton || (m.modifiers & Qt.ControlModifier) || !wasChosen)
                        return;
                    if (desk.selected.length > 1)
                        desk.selected = [icon.fileName];
                    else if (press.y >= Theme.module * 3)
                        rename.start();
                }
                // A double-click on the icon opens it, on its name renames it.
                onDoubleClicked: m => {
                    rename.stop();
                    if (m.button !== Qt.LeftButton)
                        return;
                    if (m.y >= Theme.module * 3) {
                        desk.selected = [icon.fileName];
                        desk.renaming = icon.fileName;
                    } else {
                        desk.open(desk.selected.includes(icon.fileName) ? desk.selected : [icon.fileName]);
                    }
                }

                // A click on the name of the one picked renames it, unless
                // it's the first of a double-click.
                Timer {
                    id: rename
                    interval: 500
                    onTriggered: desk.renaming = icon.fileName
                }
            }

            // Renaming: the name in a field in the cell's last module row,
            // the cell's width, all but its extension picked; Return keeps
            // it, Escape doesn't, a click elsewhere keeps it.
            Rectangle {
                visible: desk.renaming === icon.fileName
                x: 0
                y: Theme.module * 3
                width: desk.cellW
                height: Theme.module
                radius: Theme.radius / 2
                color: Colors.paper
                border.width: 1
                border.color: Colors.frame

                TextInput {
                    id: field
                    anchors.fill: parent
                    anchors.leftMargin: Theme.inset / 2
                    anchors.rightMargin: Theme.inset / 2
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    clip: true
                    color: Colors.ink
                    selectionColor: Colors.frame
                    selectedTextColor: Colors.ink
                    // The caret, drawn: a pixel-wide line in ink.
                    cursorDelegate: Rectangle {
                        width: 1
                        color: Colors.ink
                        visible: field.cursorVisible
                    }
                    font.family: Theme.font
                    font.pixelSize: Theme.textSize
                    property bool done: false
                    onVisibleChanged: if (visible) {
                        done = false;
                        text = icon.fileName;
                        forceActiveFocus();
                        const dot = icon.fileIsDir ? -1 : text.lastIndexOf(".");
                        select(0, dot > 0 ? dot : text.length);
                    }
                    Keys.onReturnPressed: finish(true)
                    Keys.onEnterPressed: finish(true)
                    Keys.onEscapePressed: finish(false)
                    onActiveFocusChanged: if (!activeFocus && visible)
                        finish(true)
                    function finish(keep) {
                        if (done)
                            return;
                        done = true;
                        if (keep)
                            desk.rename(icon.fileName, text);
                        else
                            desk.renaming = "";
                        keys.forceActiveFocus();
                    }
                }
            }
        }
    }

    // What's dragged: the picked icons as files, so apps take them too.
    Item {
        id: dragger
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
        Drag.proposedAction: Qt.MoveAction
        Drag.onDragFinished: {
            Drag.active = false;
            desk.grab = null;
            desk.target = "";
        }
    }

    // Drops: the desk's own icons move (into a folder, or to where they're
    // dropped); files from apps are copied in (into the folder they're
    // dropped on, or here where they land).
    DropArea {
        anchors.fill: parent
        onPositionChanged: drag => {
            const name = desk.nameAt(drag.x, drag.y);
            const own = drag.source === dragger;
            desk.target = name && desk.folders[name] && !(own && desk.selected.includes(name)) && !(own && desk.grab && desk.grab.name === name) ? name : "";
        }
        onExited: desk.target = ""
        onDropped: drop => {
            const into = desk.target;
            desk.target = "";
            if (drop.source === dragger) {
                const moving = desk.grab && desk.selected.includes(desk.grab.name) ? desk.selected : desk.grab ? [desk.grab.name] : [];
                if (into)
                    desk.run(["move", desk.path(into)].concat(moving.map(desk.path)), (code, out, err) => code !== 0 && desk.say(err));
                else if (desk.grab)
                    desk.reposition(drop.x, drop.y);
                drop.accept(Qt.MoveAction);
                return;
            }
            if (!drop.hasUrls)
                return;
            const paths = drop.urls.map(u => String(u)).filter(u => u.startsWith("file://")).map(u => decodeURIComponent(u.substring(7)));
            if (paths.length === 0)
                return;
            const spot = desk.cellAt(drop.x, drop.y);
            desk.run(["copy", into ? desk.path(into) : desk.dir].concat(paths), (code, out, err) => {
                if (code !== 0)
                    desk.say(err);
                if (into)
                    return;
                const p = Object.assign({}, desk.pending);
                const names = out.split("\n").filter(n => n);
                names.forEach((n, i) => p[n] = [spot[0], spot[1] + i]);
                desk.pending = p;
                desk.selected = names;
                desk.relayout();
            });
            drop.accept(Qt.CopyAction);
        }
    }

    // The right-click menu, over everything, and a click anywhere else
    // closes it.
    Dismiss {
        visible: desk.menu !== null
        onClicked: desk.menu = null
    }

    PanelWindow {
        visible: desk.menu !== null
        anchors {
            top: true
            left: true
        }
        margins.left: desk.menu ? desk.menu.x : 0
        margins.top: desk.menu ? desk.menu.y : 0
        implicitWidth: Theme.module * 6 + Theme.gap
        implicitHeight: menuRows.implicitHeight + Theme.gap
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "puter-desk-menu"

        Card {
            anchors.fill: parent

            Column {
                id: menuRows
                x: Theme.gap / 2
                y: Theme.gap / 2
                spacing: Theme.gap / 2

                Repeater {
                    model: desk.menu ? desk.menu.items : []

                    Chip {
                        required property var modelData
                        minModules: 6
                        maxModules: 6
                        hoverable: true
                        fill: "transparent"
                        ink: Colors.ink
                        text: modelData.text
                        onClicked: {
                            desk.menu = null;
                            modelData.run();
                        }
                    }
                }
            }
        }
    }

    // Deleting asks first, in the middle of the screen: Return deletes,
    // Escape doesn't.
    Dismiss {
        visible: desk.asking.length > 0
        onClicked: desk.asking = []
    }

    // Twelve modules wide, a half gap in all round: what, why, and the
    // two buttons, a module each with a half gap between.
    PanelWindow {
        visible: desk.asking.length > 0
        implicitWidth: Theme.module * 12 + Theme.gap
        implicitHeight: ask.implicitHeight + Theme.gap
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "puter-desk-delete"
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Card {
            anchors.fill: parent

            Column {
                id: ask
                x: Theme.gap / 2
                y: Theme.gap / 2
                width: parent.width - Theme.gap
                spacing: Theme.gap / 2
                focus: true
                Keys.onReturnPressed: desk.remove(desk.asking)
                Keys.onEnterPressed: desk.remove(desk.asking)
                Keys.onEscapePressed: desk.asking = []

                Item {
                    width: parent.width
                    height: Theme.module

                    Label {
                        width: parent.width - Theme.inset * 2
                        elide: Text.ElideMiddle
                        font.weight: Font.Medium
                        text: desk.asking.length === 1 ? "Delete “" + desk.asking[0] + "”?" : "Delete " + desk.asking.length + " items?"
                    }
                }

                Item {
                    width: parent.width
                    height: Theme.module

                    Label {
                        color: Colors.mutedInk
                        text: "It's gone for good: there's no trash."
                    }
                }

                Row {
                    anchors.right: parent.right
                    spacing: Theme.gap / 2

                    Chip {
                        minModules: 3
                        maxModules: 3
                        hoverable: true
                        text: "Cancel"
                        onClicked: desk.asking = []
                    }

                    Chip {
                        minModules: 3
                        maxModules: 3
                        hoverable: true
                        fill: Colors.attention
                        ink: Colors.attentionInk
                        text: "Delete"
                        onClicked: desk.remove(desk.asking)
                    }
                }
            }
        }

        onVisibleChanged: if (visible)
            ask.forceActiveFocus()
    }
}
