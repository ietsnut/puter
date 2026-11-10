import QtQuick
import QtQuick.Shapes

// puter's mark, floating at the bar's left: a thick eight-toothed gear in ink
// on a tile in the search colour. A click opens search, and the gear gives
// one playful turn: a little wind-up back, a whole turn round past where it
// started, and a settle, squashing as it's pressed.
Rectangle {
    id: tile

    signal clicked

    width: Theme.bar
    height: Theme.bar
    radius: Theme.radius
    color: mouse.containsMouse ? Colors.buttonHover : Colors.search
    Behavior on color {
        ColorAnimation {
            duration: Theme.quick
        }
    }

    // The gear's outline as an SVG path, on a 100-unit square centred at 50:
    // teeth from the root circle out to the tip, each a little narrower at
    // its tip, and a round hole in the middle (cut out by the odd-even fill).
    readonly property string path: {
        const teeth = 8, tip = 48, root = 33, hole = 14;
        const at = (r, a) => `${(50 + r * Math.cos(a)).toFixed(2)} ${(50 + r * Math.sin(a)).toFixed(2)}`;
        const step = 2 * Math.PI / teeth;
        let d = "";
        for (let i = 0; i < teeth; i++) {
            const a = i * step - Math.PI / 2;
            d += `${i ? "L" : "M"} ${at(root, a - step * 0.32)} L ${at(tip, a - step * 0.24)} L ${at(tip, a + step * 0.24)} L ${at(root, a + step * 0.32)} `;
            d += `A ${root} ${root} 0 0 1 ${at(root, a + step * 0.68)} `;
        }
        d += `Z M ${50 + hole} 50 A ${hole} ${hole} 0 1 0 ${50 - hole} 50 A ${hole} ${hole} 0 1 0 ${50 + hole} 50 Z`;
        return d;
    }

    Shape {
        id: gear
        width: 100
        height: 100
        anchors.centerIn: parent
        // 30px across, drawn on its 100-unit square.
        scale: 30 / 100 * press
        preferredRendererType: Shape.CurveRenderer

        property real press: mouse.pressed ? 0.86 : 1
        Behavior on press {
            SpringAnimation {
                spring: 6
                damping: 0.25
            }
        }

        ShapePath {
            fillColor: Colors.searchInk
            fillRule: ShapePath.OddEvenFill
            // A stroke in the fill's own colour rounds every corner of the
            // teeth: the thick, soft vector look.
            strokeColor: Colors.searchInk
            strokeWidth: 8
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: tile.path
            }
        }

        SequentialAnimation {
            id: spin
            RotationAnimation {
                target: gear
                to: -30
                duration: 140
                easing.type: Easing.OutQuad
            }
            RotationAnimation {
                target: gear
                to: 360
                direction: RotationAnimation.Clockwise
                duration: 620
                easing.type: Easing.OutBack
                easing.overshoot: 2.2
            }
            ScriptAction {
                script: gear.rotation = 0
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            spin.restart();
            tile.clicked();
        }
    }

    // Opened another way (Super+Space), it turns all the same.
    function turn() {
        spin.restart();
    }
}
