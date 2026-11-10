import QtQuick

// A popup's body: paper (unless told otherwise) at the shell's corner. Popups
// part from what's behind them by colour alone, so there's no edge. A strip
// along its top rounds its own top corners to match (topLeftRadius and
// topRightRadius: Theme.radius).
Rectangle {
    radius: Theme.radius
    color: Colors.paper
}
