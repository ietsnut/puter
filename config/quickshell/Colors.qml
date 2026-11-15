pragma Singleton
import QtQuick
import Quickshell

// Written by theme/make from theme/palette; edit those, not this.
Singleton {
    readonly property color desk: "#2a1810"
    readonly property color deskDot: "#2a1810"
    readonly property color mark: "#e5ece7"
    readonly property color folder: "#99edff"
    readonly property color bar: "#262622"
    readonly property color barInk: "#e8ebe6"
    readonly property color barEdge: "#262622"
    readonly property color search: "#99edff"
    readonly property color searchInk: "#000000"
    readonly property color tab: "#262622"
    readonly property color tabInk: "#e8ebe6"
    readonly property color tabActive: "#2e2e28"
    readonly property color tabActiveInk: "#e8ebe6"
    readonly property color paper: "#1a1a17"
    readonly property color ink: "#e8ebe6"
    readonly property color accent: "#99edff"
    readonly property color accentInk: "#000000"
    readonly property color muted: "#262622"
    readonly property color mutedInk: "#9a9a8f"
    readonly property color outline: "#262622"
    readonly property color frame: "#42423b"
    readonly property color title: "#262622"
    readonly property color titleInk: "#e8ebe6"
    readonly property color buttonHover: "#adff00"
    readonly property color buttonHoverInk: "#000000"
    readonly property color attention: "#ffc4d8"
    readonly property color attentionInk: "#000000"
    readonly property var apps: ({
        "featherpad": "#ff7a1a",
        "pcmanfm-qt": "#ab77ff",
        "utilities-terminal": "#adff00",
        "lximage-qt": "#ffc4d8",
        "firefox": "#ffd600",
        "x-office-spreadsheet": "#115ef3",
        "jlcone": "#ffc49e",
        "kicad": "#adff00",
        "pcbnew": "#adff00",
        "eeschema": "#adff00",
        "mpv": "#e0457b",
        "xdg-desktop-portal-lxqt": "#ab77ff",
        "org.mozilla.Thunderbird": "#99edff",
        "qpdfview": "#e0243c",
        "lxqt-archiver": "#5718c0",
        "accessories-calculator": "#8fb4ff",
        "qps": "#4f7a00",
        "claude": "#d4520a",
        "codex": "#99edff"
    })
}
