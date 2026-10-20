pragma Singleton
import QtQuick
import Quickshell

// The one geometry, and the colour roles from Colors.qml (written by
// theme/make from the palette). Nothing in the shell states a size or colour
// of its own.
Singleton {
    readonly property int module: 30
    readonly property int inset: 8
    // The palette's fonts, through the names fontconfig gives them
    // (config/fontconfig/conf.d, from theme/make).
    readonly property string font: "puter-sans"
    readonly property string headline: "puter-headline"
    readonly property int textSize: 15

    readonly property color desk: Colors.desk
    readonly property color deskDot: Colors.deskDot
    readonly property color bar: Colors.bar
    readonly property color barForeground: Colors.barInk
    readonly property color barEdge: Colors.barEdge
    readonly property color search: Colors.search
    readonly property color searchForeground: Colors.searchInk
    readonly property color tab: Colors.tab
    readonly property color tabForeground: Colors.tabInk
    readonly property color tabActive: Colors.tabActive
    readonly property color tabActiveForeground: Colors.tabActiveInk
    readonly property color background: Colors.paper
    readonly property color foreground: Colors.ink
    readonly property color primary: Colors.accent
    readonly property color primaryForeground: Colors.accentInk
    readonly property color muted: Colors.muted
    readonly property color mutedForeground: Colors.mutedInk
    readonly property color outline: Colors.outline
    readonly property color rule: Colors.rule
    readonly property color title: Colors.title
    readonly property color titleForeground: Colors.titleInk
    readonly property color hover: Colors.buttonHover
    readonly property color hoverForeground: Colors.buttonHoverInk
}
