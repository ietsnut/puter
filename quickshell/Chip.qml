import QtQuick

// The atom: a flat fill one module tall, its label one inset from the left.
Rectangle {
    id: chip

    property alias text: label.text
    property color fill: Theme.muted
    property color ink: Theme.mutedForeground
    property int maxWidth: 0
    signal clicked

    color: fill
    implicitHeight: Theme.module
    implicitWidth: label.implicitWidth + Theme.inset * 2
    width: maxWidth > 0 ? Math.min(implicitWidth, maxWidth) : implicitWidth

    Text {
        id: label
        x: Theme.inset
        width: chip.width - Theme.inset * 2
        anchors.verticalCenter: parent.verticalCenter
        color: chip.ink
        elide: Text.ElideRight
        font.family: Theme.font
        font.pixelSize: Theme.textSize
    }

    MouseArea {
        anchors.fill: parent
        onClicked: chip.clicked()
    }
}
