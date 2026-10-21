import QtQuick

// The thin edge around every popup and button: 1px in the outline colour,
// drawn inside its parent over whatever fills it, so the size and grid stay as
// they are. Each side can be left off, where it would only double the screen's
// own edge.
Item {
    property bool edgeTop: true
    property bool edgeRight: true
    property bool edgeBottom: true
    property bool edgeLeft: true

    anchors.fill: parent
    z: 1

    Rectangle {
        visible: parent.edgeTop
        width: parent.width
        height: 1
        color: Colors.outline
    }
    Rectangle {
        visible: parent.edgeRight
        x: parent.width - 1
        width: 1
        height: parent.height
        color: Colors.outline
    }
    Rectangle {
        visible: parent.edgeBottom
        y: parent.height - 1
        width: parent.width
        height: 1
        color: Colors.outline
    }
    Rectangle {
        visible: parent.edgeLeft
        width: 1
        height: parent.height
        color: Colors.outline
    }
}
