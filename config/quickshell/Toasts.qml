import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications

// Notifications, as toasts in the top-right corner, one module in from the
// screen's top and right edges, twelve modules wide, the newest on top and
// each flush under the one before (their edges meet on one line, as windows
// do). A toast is a strip in the app's colour (from the palette's [apps];
// the accent for an app without one, the attention colour when critical)
// holding a glyph, the app's name and a
// close button, then the summary and body on paper, every block a whole
// number of modules tall, and the actions, if any, as a row of chips. A
// click on the toast takes its default action; it goes after its timeout
// (six seconds unless the app says), or stays if critical. No animation.
PanelWindow {
    id: toasts

    // At most this many at once; older ones wait their turn under them.
    readonly property int shown: 4

    anchors {
        top: true
        right: true
    }
    margins.top: Theme.module
    margins.right: Theme.module
    implicitWidth: Theme.module * 12
    implicitHeight: Math.max(1, stack.height)
    visible: server.trackedNotifications.values.length > 0
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "puter-toasts"

    mask: Region {
        item: stack
    }

    NotificationServer {
        id: server
        keepOnReload: false
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: notification => notification.tracked = true
    }

    // The app's colour: by its desktop file's icon, or a name it gives.
    function color(notification) {
        const entry = DesktopEntries.heuristicLookup(notification.desktopEntry || notification.appName);
        for (const name of [entry?.icon, notification.desktopEntry, notification.appIcon, notification.appName.toLowerCase()])
            if (name && Colors.apps[name])
                return Colors.apps[name];
        return Colors.accent;
    }

    Column {
        id: stack
        width: toasts.width

        Repeater {
            model: server.trackedNotifications.values.slice().reverse().slice(0, toasts.shown)

            Rectangle {
                id: toast
                required property var modelData
                readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                readonly property var actions: modelData.actions.filter(action => action.identifier !== "default")
                // Rows: the strip, the text (rounded up to whole modules, one
                // inset below its last line), the actions.
                readonly property int textHeight: Math.max(image.visible ? Theme.module * 2 : 0,
                    Math.ceil((text.implicitHeight + Theme.inset * 2) / Theme.module) * Theme.module)

                width: stack.width
                height: Theme.module + textHeight + (actions.length > 0 ? Theme.module : 0)
                color: Colors.paper

                // Gone after its timeout; a critical one stays until closed.
                Timer {
                    running: !toast.critical
                    interval: toast.modelData.expireTimeout > 0 ? toast.modelData.expireTimeout * 1000 : 6000
                    onTriggered: toast.modelData.expire()
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        const action = toast.modelData.actions.find(action => action.identifier === "default");
                        if (action)
                            action.invoke();
                        else
                            toast.modelData.dismiss();
                    }
                }

                Rectangle {
                    id: strip
                    width: parent.width
                    height: Theme.module
                    // Critical ones in the attention colour, whatever the app.
                    color: toast.critical ? Colors.attention : toasts.color(toast.modelData)

                    IconImage {
                        x: (Theme.module - width) / 2
                        y: (Theme.module - height) / 2
                        implicitSize: 16
                        source: Theme.glyph(toast.critical ? "puter-notification-urgent" : "puter-notification", "status")
                    }

                    Label {
                        x: Theme.module
                        width: parent.width - Theme.module * 2
                        elide: Text.ElideRight
                        text: toast.modelData.appName || "Notification"
                    }

                    BarButton {
                        anchors.right: parent.right
                        fill: "transparent"
                        icon: "window-close"
                        onClicked: toast.modelData.dismiss()
                    }
                }

                // The app's own picture (a photo, an avatar), two modules square.
                Image {
                    id: image
                    // Not an icon by name (which apps send as their own icon):
                    // the strip already says which app it is.
                    visible: toast.modelData.image !== "" && !toast.modelData.image.startsWith("image://icon/")
                    x: 0
                    y: Theme.module
                    width: visible ? Theme.module * 2 : 0
                    height: Theme.module * 2
                    source: toast.modelData.image
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(Theme.module * 2, Theme.module * 2)
                }

                Column {
                    id: text
                    x: image.width + Theme.inset
                    y: Theme.module + Theme.inset
                    width: parent.width - x - Theme.inset

                    Text {
                        width: parent.width
                        text: toast.modelData.summary
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        color: Colors.ink
                        font.family: Theme.font
                        font.pixelSize: Theme.textSize
                        font.weight: Font.DemiBold
                        renderType: Text.CurveRendering
                    }

                    Text {
                        visible: text !== ""
                        width: parent.width
                        text: toast.modelData.body
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        color: Colors.ink
                        font.family: Theme.font
                        font.pixelSize: Theme.textSize
                        renderType: Text.CurveRendering
                    }
                }

                // The app's actions, side by side along the bottom.
                Row {
                    visible: toast.actions.length > 0
                    y: Theme.module + toast.textHeight

                    Repeater {
                        model: toast.actions

                        Chip {
                            required property var modelData
                            text: modelData.text
                            fill: Colors.muted
                            ink: Colors.ink
                            hoverable: true
                            divider: true
                            onClicked: modelData.invoke()
                        }
                    }
                }

                // A rule between the text and the actions.
                Rectangle {
                    visible: toast.actions.length > 0
                    y: Theme.module + toast.textHeight
                    width: parent.width
                    height: 1
                    color: Colors.outline
                }

                // Its edge; the top one is left to the toast above, so two
                // toasts meet on one line.
                Outline {
                    edgeTop: toast.modelData === server.trackedNotifications.values[server.trackedNotifications.values.length - 1]
                }

                // Under the strip, the edge between it and the text.
                Rectangle {
                    y: Theme.module - 1
                    width: parent.width
                    height: 1
                    color: Colors.outline
                }
            }
        }
    }
}
