import QtQuick
import Quickshell
import Quickshell.Wayland

// The desk behind every window: one plain colour with a big pixel bug in its
// middle, a different one every few seconds, and two dinosaurs standing on
// the bar.
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
    color: Colors.desk

    // The bugs' pixels: 16 of them across is eight modules.
    readonly property real bugCell: Theme.module / 2

    Item {
        anchors.centerIn: parent
        // Up a little, off the bar's two modules, so it centres on what's left.
        anchors.verticalCenterOffset: -Theme.module
        width: desk.bugCell * 16
        height: desk.bugCell * 16

        // Four bugs in turn: a beetle, a scarab, a wasp and an ant, 16
        // pixels square, drawn blobby (Pixels.qml).
        readonly property var bugs: [
            [
                ".....##...##....",
                ".......###......",
                ".##...#####...##",
                "..#...........#.",
                ".##..#######..##",
                "..#############.",
                "....#.......#...",
                ".....###.###....",
                "..#.####.####.#.",
                ".#..####.####..#",
                ".#..####.####..#",
                "....####.#.##...",
                "..#.##.#.#.##.#.",
                "..#..#.#.#.#..#.",
                "..#...........#.",
                "...#.........#.."
            ],
            [
                "....#......#....",
                "....##....##....",
                ".#....####....#.",
                ".#...######...#.",
                "..#..........#..",
                "...####..####...",
                "..############..",
                "#.####.##.####.#",
                ".###.#.##.#.###.",
                "..##.#.##.#.##..",
                "..##.#.##.#.##..",
                ".#####.##.#####.",
                "#.##.#.####.##.#",
                "...######.###...",
                "..#.##.#####.#..",
                ".#...######...#."
            ],
            [
                "................",
                ".#...#....#...#.",
                "..#..##..##..#..",
                "..#....##....#..",
                "...#..####..#...",
                "##....####....##",
                "..#.#.####.#.#..",
                "...##.####.##...",
                "..###......###..",
                ".#.##.####.##.#.",
                "#.###......###.#",
                "###.#.####.#.###",
                "##.##......##.##",
                "#.#.#.####.#.#.#",
                ".####..##..####.",
                "..##........##.."
            ],
            [
                ".#...#....#...#.",
                "..#...####...#..",
                "..#..#.##.#..#..",
                "...#.######.#...",
                "....#......#....",
                "##....####....##",
                "..#..######..#..",
                "...#.#.####.#...",
                "......####......",
                "....#......#....",
                "...#..####..#...",
                "..#..######..#..",
                "..#..#.####..#..",
                ".#...######...#.",
                ".....#.####.....",
                "......####......"
            ]
        ]
        property int bug: 0
        // What's drawn: the last bug, part way to the next while it morphs.
        property var shown: bugs[0]
        // The pixels still to flip, in the order they flip.
        property var flips: []
        // How many flip each frame: the morph takes 36 frames whatever
        // the difference.
        property int step: 1

        // Every three seconds the next bug: the pixels where the two
        // differ flip one by one, in a wave out from the middle with a
        // little chance in it, over 36 frames (about 0.6 seconds), the
        // shape staying one blob as it goes.
        Timer {
            interval: 3000
            running: true
            repeat: true
            onTriggered: {
                const tile = parent;
                tile.bug = (tile.bug + 1) % tile.bugs.length;
                const next = tile.bugs[tile.bug], cells = [];
                for (let y = 0; y < 16; y++)
                    for (let x = 0; x < 16; x++)
                        if (tile.shown[y][x] !== next[y][x])
                            cells.push({ x, y, at: Math.hypot(x - 7.5, y - 7.5) + Math.random() * 4 });
                tile.flips = cells.sort((a, b) => a.at - b.at);
                tile.step = Math.max(1, Math.ceil(cells.length / 36));
                morph.start();
            }
        }

        Timer {
            id: morph
            interval: 16
            repeat: true
            onTriggered: {
                const tile = parent, next = tile.bugs[tile.bug];
                const batch = tile.flips.splice(0, tile.step);
                const rows = tile.shown.slice();
                for (const c of batch)
                    rows[c.y] = rows[c.y].substring(0, c.x) + next[c.y][c.x] + rows[c.y].substring(c.x + 1);
                tile.shown = rows;
                if (tile.flips.length === 0)
                    stop();
            }
        }

        Pixels {
            anchors.centerIn: parent
            cell: desk.bugCell
            ink: Colors.mark
            rows: parent.shown
        }
    }

    // Two dinosaurs standing on the bar: a sauropod on the windows' pill,
    // near its start, facing right, and a rex on the right pill, near its
    // end. They're the desk's, so any window covers them; their feet meet the pills' tops.
    readonly property real dinoCell: Theme.module / 4
    readonly property real barTop: height - Theme.module * 2 + Theme.gap

    Pixels {
        x: Theme.gap + Theme.bar + Theme.gap * 3
        y: desk.barTop - height
        cell: desk.dinoCell
        ink: Colors.dino1
        rows: [
            "..........####",
            "....#####.##.#",
            "...###########",
            ".#############",
            "###########...",
            "...###..###...",
            "...###..###..."
        ]
    }

    Pixels {
        x: desk.width - Theme.module * 3 - width
        y: desk.barTop - height
        cell: desk.dinoCell
        ink: Colors.dino2
        rows: [
            ".####.........",
            "##.##.........",
            "######........",
            "...####......#",
            "..############",
            "...#########..",
            "..#######.....",
            "....#..#......",
            "....#..#......",
            "...##.##......"
        ]
    }
}
