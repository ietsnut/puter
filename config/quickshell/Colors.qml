pragma Singleton
import QtQuick
import Quickshell

// Written by theme/make from theme/palette; edit those, not this.
Singleton {
    readonly property color desk: "#583127"
    readonly property color deskDot: "#f1f0ec"
    readonly property color bar: "#f1f0ec"
    readonly property color barInk: "#060606"
    readonly property color barEdge: "#f1f0ec"
    readonly property color search: "#f1f0ec"
    readonly property color searchInk: "#060606"
    readonly property color tab: "#f1f0ec"
    readonly property color tabInk: "#060606"
    readonly property color tabActive: "#ffffff"
    readonly property color tabActiveInk: "#060606"
    readonly property color paper: "#ffffff"
    readonly property color ink: "#060606"
    readonly property color accent: "#e0a9df"
    readonly property color accentInk: "#060606"
    readonly property color muted: "#f1f0ec"
    readonly property color mutedInk: "#6b6459"
    readonly property color outline: "#060606"
    readonly property color rule: "#d6d1cb"
    readonly property color title: "#f1f0ec"
    readonly property color titleInk: "#060606"
    readonly property color buttonHover: "#4a4446"
    readonly property color buttonHoverInk: "#ffffff"
    readonly property color attention: "#e4722c"
    readonly property color attentionInk: "#060606"
    readonly property var apps: ({
        "featherpad": "#e4722c",
        "pcmanfm-qt": "#e0a9df",
        "utilities-terminal": "#9cb747",
        "lximage-qt": "#a9a7f9",
        "firefox": "#f2c14e",
        "x-office-spreadsheet": "#c9d1e2",
        "jlcone": "#f0a27a",
        "kicad": "#583127",
        "pcbnew": "#583127",
        "eeschema": "#583127",
        "mpv": "#e88fb0",
        "xdg-desktop-portal-lxqt": "#e0a9df",
        "qpdfview": "#c8372d",
        "lxqt-archiver": "#7a52c4",
        "accessories-calculator": "#5552c4",
        "qps": "#5f7a1e",
        "claude": "#b85926",
        "codex": "#3e8fa8"
    })
}
