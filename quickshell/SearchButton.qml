import QtQuick

// A two-module square of ink with a magnifier in it. The glyph keeps to the
// 20 x 20 box in the middle and is drawn as the window buttons are: 2 x 2
// blocks on whole pixels, so every stroke is 2px and nothing is antialiased.
Rectangle {
    id: button

    signal clicked

    // The magnifier, one character per block: a round lens with the handle
    // running out to the box's corner.
    readonly property var glyph: [
        "..###.....",
        ".#...#....",
        "#.....#...",
        "#.....#...",
        "#.....#...",
        ".#...#....",
        "..###.#...",
        ".......#..",
        "........#.",
        ".........#",
    ]
    readonly property color ink: mouse.containsMouse ? Theme.mutedForeground : Theme.background

    width: Theme.module * 2
    height: Theme.module * 2
    color: mouse.containsMouse ? Theme.muted : Theme.foreground

    Repeater {
        model: button.glyph.join("").length

        Rectangle {
            required property int index
            readonly property int column: index % 10
            readonly property int row: Math.floor(index / 10)

            visible: button.glyph[row][column] === "#"
            x: 20 + column * 2
            y: 20 + row * 2
            width: 2
            height: 2
            color: button.ink
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()
    }
}
