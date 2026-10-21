import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Alt+Tab: the open windows as cards in the middle of the screen, the one
// used last first, each a preview of the window over a title strip with
// the app's square and the window's title. Holding Alt, Tab steps on
// (Shift+Tab back, or the arrow keys); letting go of Alt goes to the one
// picked. A quick Alt+Tab goes straight back to the last window: the cards
// only show once Alt has been held a moment. A click picks one too, Escape
// or a click elsewhere goes back, Delete closes the picked window.
//
// Cards are six modules tall (five of preview, one of title) and as wide as
// their window's preview needs, in whole modules (five to fourteen): flush
// side by side so neighbours share an edge, as many to a row as fit the
// screen, straight on the desk. The previews are taken as it opens and four
// times a second while it's open: grim captures each window on its own
// (`grim -T`, by the identifier puter-windows lists, src/windows), since
// Quickshell can only capture single windows on Hyprland.
//
// labwc runs `qs ipc call switcher next` (or previous) on Alt+Tab; once
// open, the switcher has the keyboard and hears Alt let go. Its surface is
// always there, empty and taking no input while closed, so it has the
// keyboard the moment it opens (a release before then would be missed).
PanelWindow {
    id: switcher

    // Open: it has the keyboard. Shown: the cards are up.
    property bool shown: false
    property bool open: false
    // The windows as they were when it opened, and the one picked.
    property var windows: []
    property int selected: 0

    // Most recently used first: each window moves to the front when it's
    // activated; ones never activated since the shell started keep their
    // order behind them.
    property var used: []

    // The previews: the folder grim writes them to, each window's identifier
    // in it (matched by app ID and title, and their order where two windows
    // share both), and a count that makes the images load afresh.
    readonly property string shots: Quickshell.env("XDG_RUNTIME_DIR") + "/puter-switcher"
    property var identifiers: new Map()
    property int frame: 0
    // The previews are written to two files in turn, A and B; this is the
    // one written last, so an image never loads one half-written.
    property string side: "A"

    function identifier(window) {
        const same = windows.filter(w => w.appId === window.appId && w.title === window.title);
        const ids = identifiers.get(window.appId + "\t" + window.title) ?? [];
        return ids[same.indexOf(window)] ?? "";
    }

    // Before its first preview, a card is eight modules wide.
    readonly property int cardWidth: Theme.module * 8
    // The widest the cards can run: the screen less a module each side.
    readonly property int rowWidth: Math.floor(width / Theme.module - 2) * Theme.module
    readonly property int cardHeight: Theme.module * 6

    function order() {
        const all = ToplevelManager.toplevels.values;
        const recent = used.filter(window => all.includes(window));
        return recent.concat(all.filter(window => !recent.includes(window)));
    }

    function step(by) {
        if (!open) {
            windows = order();
            if (windows.length === 0)
                return;
            // From the window in use: one on is the one before it.
            selected = (by > 0 ? Math.min(1, windows.length - 1) : windows.length - 1);
            open = true;
            showing.restart();
            capture.running = true;
            return;
        }
        shown = true;
        const n = windows.length;
        selected = ((selected + by) % n + n) % n;
    }

    // Up and down a row: to the card there nearest the one picked.
    function row(by) {
        const here = cards.itemAt(selected);
        if (!here)
            return;
        let best = -1, distance = Infinity;
        for (let i = 0; i < cards.count; i++) {
            const card = cards.itemAt(i);
            if (card.y !== here.y + by * cardHeight)
                continue;
            const d = Math.abs(card.x + card.width / 2 - here.x - here.width / 2);
            if (d < distance) {
                best = i;
                distance = d;
            }
        }
        if (best >= 0)
            selected = best;
    }

    function pick() {
        const window = windows[selected];
        open = false;
        shown = false;
        windows = [];
        if (window)
            window.activate();
    }

    function cancel() {
        open = false;
        shown = false;
        windows = [];
    }

    function closeSelected() {
        const window = windows[selected];
        if (!window)
            return;
        window.close();
        windows = windows.filter(w => w !== window);
        if (windows.length === 0)
            cancel();
        else
            selected = Math.min(selected, windows.length - 1);
    }

    // Keeps the order of use.
    Repeater {
        model: ToplevelManager.toplevels

        Item {
            required property var modelData

            Connections {
                target: modelData

                function onActivatedChanged() {
                    if (modelData.activated)
                        switcher.used = [modelData].concat(switcher.used.filter(window => window !== modelData));
                }
            }

            Component.onCompleted: {
                if (modelData.activated)
                    switcher.used = [modelData].concat(switcher.used.filter(window => window !== modelData));
            }
        }
    }

    Timer {
        id: showing
        interval: 120
        onTriggered: if (switcher.open) switcher.shown = true
    }

    // Every window captured at once, to the file not on screen, then the list
    // of them (identifier, app ID, title).
    Process {
        id: capture
        readonly property string side: switcher.side === "A" ? "B" : "A"
        // Previews of windows closed a while ago go.
        command: ["sh", "-c", `dir="${switcher.shots}"; mkdir -p "$dir"
            find "$dir" -type f -mmin +10 -delete
            # The loop runs in the pipe's subshell, so that's where it waits.
            puter-windows | { while IFS="$(printf '\t')" read -r id app title; do
                grim -T "$id" -t ppm "$dir/$id-${side}.ppm" 2>/dev/null &
            done; wait; }; puter-windows`]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = new Map();
                for (const line of text.split("\n").filter(line => line !== "")) {
                    const [id, app, title] = line.split("\t");
                    const key = app + "\t" + (title ?? "");
                    map.set(key, (map.get(key) ?? []).concat([id]));
                }
                switcher.identifiers = map;
                switcher.side = capture.side;
                switcher.frame++;
            }
        }
    }

    Timer {
        running: switcher.open
        interval: 250
        repeat: true
        onTriggered: if (!capture.running) capture.running = true
    }

    // A window that closes while it's open drops out.
    Connections {
        target: ToplevelManager.toplevels

        function onObjectRemovedPost(object, index) {
            if (!switcher.open)
                return;
            switcher.windows = switcher.windows.filter(window => window !== object);
            if (switcher.windows.length === 0)
                switcher.cancel();
            else
                switcher.selected = Math.min(switcher.selected, switcher.windows.length - 1);
        }
    }

    // Input only while open.
    Region {
        id: nothing
    }

    mask: open ? null : nothing
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "puter-switcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // A click beside the cards goes back.
    MouseArea {
        anchors.fill: parent
        onClicked: switcher.cancel()
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right)
                switcher.step(1);
            else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Left)
                switcher.step(-1);
            else if (event.key === Qt.Key_Down)
                switcher.row(1);
            else if (event.key === Qt.Key_Up)
                switcher.row(-1);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                switcher.pick();
            else if (event.key === Qt.Key_Escape)
                switcher.cancel();
            else if (event.key === Qt.Key_Delete)
                switcher.closeSelected();
            event.accepted = true;
        }
        Keys.onReleased: event => {
            if (event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr || event.key === Qt.Key_Meta || !(event.modifiers & Qt.AltModifier))
                switcher.pick();
            event.accepted = true;
        }
    }

    onOpenChanged: if (open) keys.forceActiveFocus()

    // The cards together, in the middle of the screen with every edge on
    // the grid.
    Rectangle {
        id: sheet
        visible: switcher.shown
        width: flow.childrenRect.width
        height: flow.childrenRect.height
        x: Math.round((switcher.width - width) / 2 / Theme.module) * Theme.module
        y: Math.round((switcher.height - Theme.module - height) / 2 / Theme.module) * Theme.module
        color: "transparent"

        // Takes clicks between the cards, so they don't go back.
        MouseArea {
            anchors.fill: parent
        }

        Flow {
            id: flow
            width: switcher.rowWidth

            Repeater {
                id: cards
                model: switcher.shown ? switcher.windows : []

                Item {
                    id: card
                    required property var modelData
                    required property int index
                    readonly property bool current: index === switcher.selected
                    readonly property var entry: DesktopEntries.heuristicLookup(modelData.appId)

                    // The preview at the card's full height (less an inset
                    // above and below), and the card the whole modules
                    // around it, an inset either side.
                    width: shot.implicitHeight > 0
                        ? Math.max(5, Math.min(14, Math.ceil(((Theme.module * 5 - Theme.inset * 2) * shot.implicitWidth / shot.implicitHeight + Theme.inset * 2) / Theme.module))) * Theme.module
                        : switcher.cardWidth
                    height: switcher.cardHeight

                    // The preview, fitted inside the card one inset from its
                    // edges, on the bar's colour (and only that, until the
                    // first one's taken). Loaded in step, so a new frame
                    // replaces the last without a gap.
                    Rectangle {
                        id: preview
                        width: parent.width
                        height: Theme.module * 5
                        color: Theme.muted

                        Image {
                            id: shot
                            readonly property string id: switcher.frame >= 0 ? switcher.identifier(card.modelData) : ""
                            anchors.centerIn: parent
                            width: preview.width - Theme.inset * 2
                            height: preview.height - Theme.inset * 2
                            fillMode: Image.PreserveAspectFit
                            asynchronous: false
                            cache: false
                            // Captured whole and scaled down once, as it loads, to
                            // the height it's shown at: Qt's smooth scaling
                            // averages the pixels (drawing it smaller would
                            // only sample them, which shimmers and jags).
                            sourceSize.height: height
                            smooth: true
                            source: id ? "file://" + switcher.shots + "/" + id + "-" + switcher.side + ".ppm" : ""
                        }
                    }

                    Chip {
                        y: Theme.module * 5
                        minModules: card.width / Theme.module
                        maxModules: card.width / Theme.module
                        text: card.modelData.title || card.entry?.name || card.modelData.appId
                        icon: Quickshell.iconPath(card.entry?.icon ?? card.modelData.appId, true)
                        // The picked one in ink, so every app's square shows on it.
                        fill: card.current ? Theme.foreground : Theme.title
                        ink: card.current ? Theme.background : Theme.titleForeground
                    }

                    // Each card's edge; where two meet they share a line.
                    Outline {
                        edgeLeft: card.x === 0
                        edgeTop: card.y === 0
                    }

                    // The line between preview and title.
                    Rectangle {
                        y: Theme.module * 5
                        width: parent.width
                        height: 1
                        color: Theme.outline
                        z: 2
                    }

                    // The picked card: a second line inside its edge.
                    Rectangle {
                        visible: card.current
                        anchors.fill: parent
                        anchors.margins: 1
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.outline
                        z: 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        z: 3
                        onEntered: switcher.selected = card.index
                        onClicked: switcher.pick()
                    }
                }
            }
        }

    }
}
