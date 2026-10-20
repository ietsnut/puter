import QtQuick
import Quickshell
import Quickshell.Wayland

// Search: apps by name. It stands on the search square, flush with the left
// edge, sixteen modules wide and one module per row, the best match nearest
// the input. Every edge is on the grid. Type to filter, Up and Down to move, Return to open,
// Escape to close.
PanelWindow {
    id: panel

    property string query: ""
    property int selected: 0

    readonly property var results: DesktopEntries.applications.values
        .filter(entry => !entry.noDisplay && entry.name.toLowerCase().includes(query.toLowerCase()))
        .sort((a, b) => a.name.localeCompare(b.name))
        .slice(0, 10)

    function toggle() {
        visible = !visible;
    }

    function open(entry) {
        entry.execute();
        visible = false;
    }

    visible: false
    anchors {
        bottom: true
        left: true
    }
    margins.bottom: Theme.module * 2
    implicitWidth: Theme.module * 16
    implicitHeight: Theme.module * (results.length + 1)
    exclusionMode: ExclusionMode.Ignore
    color: Theme.background
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: {
        query = "";
        selected = 0;
        if (visible)
            input.forceActiveFocus();
    }
    onQueryChanged: selected = 0

    Column {
        width: parent.width

        // Best match last, right above the input; Up moves away from it.
        Repeater {
            model: panel.results.slice().reverse()

            Rectangle {
                required property var modelData
                required property int index
                readonly property bool current: panel.results.length - 1 - index === panel.selected

                width: parent.width
                height: Theme.module
                color: current ? Theme.muted : Theme.background

                Text {
                    x: Theme.inset
                    width: parent.width - Theme.inset * 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name
                    elide: Text.ElideRight
                    color: current ? Theme.mutedForeground : Theme.foreground
                    font.family: Theme.font
                    renderType: Text.CurveRendering
                    font.pixelSize: Theme.textSize
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: panel.open(modelData)
                }
            }
        }

        Rectangle {
            width: parent.width
            height: Theme.module
            color: Theme.foreground

            TextInput {
                id: input
                x: Theme.inset
                width: parent.width - Theme.inset * 2
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.background
                selectionColor: Theme.background
                selectedTextColor: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.textSize
                onTextChanged: panel.query = text

                Keys.onEscapePressed: panel.visible = false
                Keys.onUpPressed: panel.selected = Math.min(panel.selected + 1, panel.results.length - 1)
                Keys.onDownPressed: panel.selected = Math.max(panel.selected - 1, 0)
                Keys.onReturnPressed: {
                    if (panel.results.length > 0)
                        panel.open(panel.results[panel.selected]);
                }

                Text {
                    visible: !input.text
                    text: "Search"
                    color: Theme.muted
                    font: input.font
                }
            }
        }
    }
}
