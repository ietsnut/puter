import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Search: apps by name. It stands on the search square, flush with the left
// edge, sixteen modules wide and one module per row, the best match nearest
// the input; with nothing typed it lists the apps opened most recently. Every
// edge is on the grid. Type to filter, point or use Up and Down to pick,
// click or Return to open, Escape to close.
PanelWindow {
    id: panel

    property string query: ""
    property int selected: 0

    readonly property var apps: DesktopEntries.applications.values.filter(entry => !entry.noDisplay)
    readonly property var recentApps: recent.ids.map(id => DesktopEntries.byId(id)).filter(entry => entry)
    readonly property var results: query === "" && recentApps.length > 0 ? recentApps
        : apps.filter(entry => entry.name.toLowerCase().includes(query.toLowerCase()))
              .sort((a, b) => a.name.localeCompare(b.name))
              .slice(0, 10)

    function toggle() {
        visible = !visible;
    }

    function open(entry) {
        remember(entry);
        entry.execute();
        visible = false;
    }

    // Most recent first, ten at most, kept on disk across restarts.
    function remember(entry) {
        if (!entry || !entry.id)
            return;
        recent.ids = [entry.id].concat(recent.ids.filter(id => id !== entry.id)).slice(0, 10);
        store.writeAdapter();
    }

    FileView {
        id: store
        path: Quickshell.statePath("recent.json")
        printErrors: false

        JsonAdapter {
            id: recent
            property list<string> ids: []
        }
    }

    // Apps opened any other way (a terminal, a file in Thunar) count as well:
    // each new window is matched to its app.
    Connections {
        target: ToplevelManager.toplevels

        function onObjectInsertedPost(object, index) {
            appLookup.toplevel = object;
            appLookup.restart();
        }
    }

    // A new window may only name its app a moment after it appears.
    Timer {
        id: appLookup
        property var toplevel: null
        interval: 500
        onTriggered: {
            if (toplevel && toplevel.appId)
                panel.remember(DesktopEntries.heuristicLookup(toplevel.appId));
        }
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

    // Every open starts afresh: no text, the most recent app selected.
    onVisibleChanged: {
        input.clear();
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
                color: current ? Theme.primary : Theme.background

                Text {
                    x: Theme.inset
                    width: parent.width - Theme.inset * 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name
                    elide: Text.ElideRight
                    color: current ? Theme.primaryForeground : Theme.foreground
                    font.family: Theme.font
                    renderType: Text.CurveRendering
                    font.pixelSize: Theme.textSize
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: panel.selected = panel.results.length - 1 - index
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
                    text: panel.recentApps.length > 0 ? "Search, or pick a recent app" : "Search"
                    color: Theme.muted
                    font: input.font
                }
            }
        }
    }
}
