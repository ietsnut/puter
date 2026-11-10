import QtQuick
import QtQuick.Shapes

// Pixel art, blobby: a drawing given as rows of "#" (a pixel) and "." (none),
// drawn as one shape whose pixels merge, every corner of its outline filleted
// half a pixel round, convex and concave alike, so lone pixels are dots,
// one-pixel lines have round ends and diagonal steps join by a neck. As
// puter's icons are drawn (theme/make).
Shape {
    id: pixels

    property var rows: []
    property color ink: Colors.ink
    // One pixel's side.
    property real cell: 2

    readonly property int columns: Math.max(0, ...rows.map(row => row.length))
    width: columns * cell
    height: rows.length * cell
    preferredRendererType: Shape.CurveRenderer

    // The outline: every pixel edge with no pixel across it, directed so the
    // pixels are on its right, chained into loops (taking the left turn
    // where two pixels touch only at a corner, so they merge), then each
    // corner swapped for a curve from half a pixel before it to half after.
    function outline() {
        const filled = (x, y) => y >= 0 && y < rows.length && rows[y][x] === "#";
        const key = (x, y) => x + "," + y;
        const edges = new Map();
        const add = (ax, ay, bx, by) => {
            const k = key(ax, ay);
            if (!edges.has(k))
                edges.set(k, []);
            edges.get(k).push([bx, by]);
        };
        for (let y = 0; y < rows.length; y++)
            for (let x = 0; x < rows[y].length; x++) {
                if (!filled(x, y))
                    continue;
                if (!filled(x, y - 1)) add(x, y, x + 1, y);
                if (!filled(x + 1, y)) add(x + 1, y, x + 1, y + 1);
                if (!filled(x, y + 1)) add(x + 1, y + 1, x, y + 1);
                if (!filled(x - 1, y)) add(x, y + 1, x, y);
            }
        const take = (k, pick) => {
            const outs = edges.get(k);
            const next = outs.splice(pick(outs), 1)[0];
            if (outs.length === 0)
                edges.delete(k);
            return next;
        };
        let d = "";
        while (edges.size > 0) {
            const start = edges.keys().next().value.split(",").map(Number);
            let points = [start], prev = start;
            let cur = take(key(...start), () => 0);
            while (key(...cur) !== key(...start) || edges.has(key(...start)) && false) {
                points.push(cur);
                const dx = cur[0] - prev[0], dy = cur[1] - prev[1];
                const next = take(key(...cur), outs => outs.length > 1
                    ? outs.findIndex(o => o[0] - cur[0] === dy && o[1] - cur[1] === -dx) : 0);
                prev = cur;
                cur = next;
            }
            // Corners only: drop points along a straight run.
            points = points.filter((c, i) => {
                const p = points[(i + points.length - 1) % points.length], q = points[(i + 1) % points.length];
                return (c[0] - p[0]) * (q[1] - c[1]) - (c[1] - p[1]) * (q[0] - c[0]) !== 0;
            });
            const toward = (c, o) => {
                const dx = o[0] - c[0], dy = o[1] - c[1], l = Math.abs(dx) + Math.abs(dy);
                return [(c[0] + dx / l * 0.5) * cell, (c[1] + dy / l * 0.5) * cell];
            };
            points.forEach((c, i) => {
                const a = toward(c, points[(i + points.length - 1) % points.length]);
                const b = toward(c, points[(i + 1) % points.length]);
                d += `${i ? "L" : "M"} ${a[0]} ${a[1]} Q ${c[0] * cell} ${c[1] * cell} ${b[0]} ${b[1]} `;
            });
            d += "Z ";
        }
        return d;
    }

    ShapePath {
        fillColor: pixels.ink
        strokeColor: "transparent"
        fillRule: ShapePath.OddEvenFill
        PathSvg {
            path: pixels.outline()
        }
    }
}
