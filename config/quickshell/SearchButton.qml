import QtQuick
import QtQuick.Shapes

// A two-module square of paper with a magnifier in ink and the 1px outline
// inside its edges, like the desk's buttons; gray under the pointer. The glyph keeps to the
// 20 x 20 box in the middle, drawn as the window buttons are: 2px vector
// strokes, the handle clipped square where it meets the box's corner.
Rectangle {
    id: button

    signal clicked

    readonly property color ink: mouse.containsMouse ? Theme.hoverForeground : Theme.foreground

    width: Theme.module * 2
    height: Theme.module * 2
    color: mouse.containsMouse ? Theme.hover : Theme.background

    Item {
        x: 20
        y: 20
        width: 20
        height: 20
        clip: true

        Shape {
            x: -20
            y: -20
            width: 60
            height: 60
            preferredRendererType: Shape.CurveRenderer

            // The lens: the middle of its 2px stroke on a 7px radius, so its
            // outer edge runs from 20 to 36.
            ShapePath {
                strokeColor: button.ink
                strokeWidth: 2
                fillColor: "transparent"

                PathAngleArc {
                    centerX: 28
                    centerY: 28
                    radiusX: 7
                    radiusY: 7
                    startAngle: 0
                    sweepAngle: 360
                }
            }

            // The handle, from inside the lens's stroke out past the corner.
            ShapePath {
                strokeColor: button.ink
                strokeWidth: 2
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                startX: 32
                startY: 32

                PathLine {
                    x: 42
                    y: 42
                }
            }
        }
    }

    Outline {
        edgeBottom: false
        edgeLeft: false
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()
    }
}
