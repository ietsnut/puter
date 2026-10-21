pragma Singleton
import QtQuick
import Quickshell

// What each agent window is doing, by its title (bin/puter-agent locks an
// agent window's title, and its hooks report under it): "working", "waiting"
// (for you: a permission to give) or "done" (its turn is over); a window
// with no state isn't an agent, or is idle. Set over IPC (shell.qml).
Singleton {
    property var states: ({})

    function set(title: string, state: string) {
        const next = Object.assign({}, states);
        if (state)
            next[title] = state;
        else
            delete next[title];
        states = next;
    }
}
