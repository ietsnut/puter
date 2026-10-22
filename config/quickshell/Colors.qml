pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Written by theme/make from theme/palette; edit those, not this. Each
// role in the light look and the dark one, which ~/.config/puter/mode
// chooses (bin/puter-mode), followed as it changes.
Singleton {
    readonly property bool dark: mode.text().trim() === "dark"

    FileView {
        id: mode
        path: Quickshell.env("HOME") + "/.config/puter/mode"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }

    // Read again (bin/puter-mode asks, over IPC: shell.qml).
    function reload() {
        mode.reload();
    }

    readonly property color desk: dark ? "#583127" : "#583127"
    readonly property color deskDot: dark ? "#f1f0ec" : "#f1f0ec"
    readonly property color bar: dark ? "#231f20" : "#f1f0ec"
    readonly property color barInk: dark ? "#f1f0ec" : "#060606"
    readonly property color barEdge: dark ? "#231f20" : "#f1f0ec"
    readonly property color search: dark ? "#231f20" : "#f1f0ec"
    readonly property color tab: dark ? "#231f20" : "#f1f0ec"
    readonly property color tabInk: dark ? "#f1f0ec" : "#060606"
    readonly property color tabActive: dark ? "#4a4446" : "#ffffff"
    readonly property color tabActiveInk: dark ? "#f1f0ec" : "#060606"
    readonly property color paper: dark ? "#231f20" : "#ffffff"
    readonly property color ink: dark ? "#f1f0ec" : "#060606"
    readonly property color accent: dark ? "#e0a9df" : "#e0a9df"
    readonly property color accentInk: dark ? "#060606" : "#060606"
    readonly property color muted: dark ? "#4a4446" : "#f1f0ec"
    readonly property color mutedInk: dark ? "#958d79" : "#6b6459"
    readonly property color outline: dark ? "#060606" : "#060606"
    readonly property color title: dark ? "#4a4446" : "#f1f0ec"
    readonly property color titleInk: dark ? "#f1f0ec" : "#060606"
    readonly property color buttonHover: dark ? "#6b6459" : "#4a4446"
    readonly property color buttonHoverInk: dark ? "#ffffff" : "#ffffff"
    readonly property color attention: dark ? "#e4722c" : "#e4722c"
    readonly property color attentionInk: dark ? "#060606" : "#060606"
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
        "org.mozilla.Thunderbird": "#b28600",
        "qpdfview": "#c8372d",
        "lxqt-archiver": "#7a52c4",
        "accessories-calculator": "#5552c4",
        "qps": "#5f7a1e",
        "claude": "#b85926",
        "codex": "#3e8fa8"
    })
}
