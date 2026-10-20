import QtQuick

// A dot matrix, after the dotted charts of the stack look: a grid of square
// cells, a whole number of them to a module, each holding a square in the
// accent when it's on and a small dot in the rule colour when it's off.
// Each column is on from the bottom up to its value.
Item {
    id: matrix

    // How many cells are on in each column, from the bottom.
    property var columns: []
    property int rows: 3
    // A cell, and the square of one that's on, centred in it.
    property int cell: 10
    property int dot: 6
    property int offDot: 2
    property color on: Theme.primary
    property color off: Theme.rule

    width: columns.length * cell
    height: rows * cell

    Repeater {
        model: matrix.columns.length * matrix.rows

        Rectangle {
            required property int index
            readonly property int column: Math.floor(index / matrix.rows)
            readonly property int row: index % matrix.rows  // 0 at the bottom
            readonly property bool lit: row < matrix.columns[column]
            readonly property int size: lit ? matrix.dot : matrix.offDot
            x: column * matrix.cell + (matrix.cell - size) / 2
            y: (matrix.rows - 1 - row) * matrix.cell + (matrix.cell - size) / 2
            width: size
            height: size
            color: lit ? matrix.on : matrix.off
        }
    }
}
