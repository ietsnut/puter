import QtQuick

// A popup's body: paper (unless told otherwise) at the shell's corner, with
// a 1px frame round it (the palette's frame colour) drawn over whatever it
// holds, so a title strip doesn't cover it. A strip along its top rounds its
// own top corners to match (topLeftRadius and topRightRadius: Theme.radius).
Rectangle {
    radius: Theme.radius
    color: Colors.paper

    Rectangle {
        anchors.fill: parent
        z: 1000
        radius: parent.radius
        color: "transparent"
        border.width: 1
        border.color: Colors.frame
    }
}
