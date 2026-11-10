import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Search: apps by name, in a card centred a little above the middle of the
// screen, as Spotlight is. The query is set large; below it, the matches, the
// best first, with nothing typed the apps opened most recently. The card
// rises in and grows with its results; the selection glides between them.
// Type to filter, point or use Up and Down to pick, click or Return to open,
// Escape or a click anywhere else to close.
PanelWindow {
    id: panel

    property string query: ""
    property int selected: 0

    readonly property var apps: DesktopEntries.applications.values.filter(entry => !entry.noDisplay)
    // Found among apps rather than with DesktopEntries.byId, so they're looked
    // up again whenever the apps change: when an app is installed or its
    // desktop file rewritten, the old entries are deleted, and holding on to
    // one crashes the shell.
    readonly property var recentApps: recent.ids.map(id => apps.find(entry => entry.id === id)).filter(entry => entry)
    readonly property var results: query === "" && recentApps.length > 0 ? recentApps
        : apps.filter(entry => entry.name.toLowerCase().includes(query.toLowerCase()))
              .sort((a, b) => a.name.localeCompare(b.name))
              .slice(0, 8)

    // Opening shows the window and lets the card in; closing lets it out
    // first, and the window goes once it has.
    property bool shown: false

    function toggle() {
        if (shown)
            close();
        else {
            visible = true;
            shown = true;
        }
    }

    function close() {
        shown = false;
    }

    function open(entry) {
        remember(entry);
        entry.execute();
        close();
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
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Every open starts afresh: no text, the first result selected.
    onShownChanged: {
        if (!shown)
            return;
        input.clear();
        query = "";
        selected = 0;
        input.forceActiveFocus();
    }
    onQueryChanged: selected = 0

    // A click anywhere off the card closes it.
    MouseArea {
        anchors.fill: parent
        onClicked: panel.close()
    }

    Rectangle {
        id: card
        width: Theme.module * 20
        height: field.height + (list.count > 0 ? list.height + Theme.gap / 2 : 0) + Theme.gap / 2 * 2
        x: (panel.width - width) / 2
        y: panel.height * 0.22 + (panel.shown ? 0 : Theme.gap)
        radius: Theme.radius
        // The bar's colour, so it stands apart from the paper windows
        // without an outline.
        color: Colors.bar
        clip: true
        opacity: panel.shown ? 1 : 0
        scale: panel.shown ? 1 : 0.97

        Behavior on height {
            NumberAnimation {
                duration: Theme.open
                easing.type: Easing.OutCubic
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: Theme.open
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.open
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.open * 0.7
                easing.type: Easing.OutCubic
                onRunningChanged: {
                    if (!running && !panel.shown)
                        panel.visible = false;
                }
            }
        }

        // Clicks on the card stay on it.
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: field
            x: Theme.gap / 2
            y: Theme.gap / 2
            width: card.width - Theme.gap
            height: Theme.module * 2 - Theme.gap

            TextInput {
                id: input
                x: Theme.inset + Theme.gap / 2
                width: parent.width - x * 2
                anchors.verticalCenter: parent.verticalCenter
                color: Colors.ink
                selectionColor: Colors.accent
                selectedTextColor: Colors.accentInk
                font.family: Theme.font
                font.pixelSize: Theme.queryText
                font.weight: Font.Medium
                onTextChanged: panel.query = text

                Keys.onEscapePressed: panel.close()
                Keys.onUpPressed: panel.selected = Math.max(panel.selected - 1, 0)
                Keys.onDownPressed: panel.selected = Math.min(panel.selected + 1, panel.results.length - 1)
                Keys.onReturnPressed: {
                    if (panel.results.length > 0)
                        panel.open(panel.results[panel.selected]);
                }

                Text {
                    visible: !input.text
                    text: "Search"
                    color: Colors.mutedInk
                    font: input.font
                }
            }
        }

        ListView {
            id: list
            x: Theme.gap / 2
            y: field.y + field.height + Theme.gap / 2
            width: field.width
            height: count * Theme.bar
            interactive: false
            model: panel.results
            currentIndex: panel.selected

            // One highlight, gliding to whichever row is selected.
            highlightFollowsCurrentItem: true
            highlightMoveDuration: Theme.quick * 1.5
            highlightMoveVelocity: -1
            highlight: Rectangle {
                radius: Theme.radius / 2
                color: Colors.accent
            }

            delegate: Item {
                required property var modelData
                required property int index
                width: list.width
                height: Theme.bar

                Image {
                    id: icon
                    x: (Theme.bar - width) / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    sourceSize: Qt.size(16, 16)
                    source: Quickshell.iconPath(modelData.icon, true)
                }

                Text {
                    x: Theme.bar
                    width: parent.width - x - Theme.inset
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name
                    elide: Text.ElideRight
                    color: index === panel.selected ? Colors.accentInk : Colors.ink
                    font.family: Theme.font
                    font.pixelSize: Theme.textSize
                    font.weight: Font.Medium
                    renderType: Text.CurveRendering
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: panel.selected = index
                    onClicked: panel.open(modelData)
                }
            }
        }
    }
}
