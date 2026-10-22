import Quickshell
import Quickshell.Io

ShellRoot {
    Desk {}

    Bar {
        id: bar
        updates: updatesPanel.barState
        onSearch: searchPanel.toggle()
        onUpdate: updatesPanel.toggle()
        onVolume: volumePanel.toggle()
    }

    Dismiss {
        visible: searchPanel.visible || updatesPanel.visible || volumePanel.visible
        onClicked: {
            searchPanel.visible = false;
            updatesPanel.visible = false;
            volumePanel.visible = false;
        }
    }

    SearchPanel {
        id: searchPanel
    }

    Updates {
        id: updatesPanel
    }

    Volume {
        id: volumePanel
    }

    Toasts {}

    Switcher {
        id: switcher
    }

    // bin/puter-mode, having changed the look: `qs ipc call look changed`.
    IpcHandler {
        target: "look"

        function changed(): void {
            Colors.reload();
        }
    }

    // Super+Space: `qs ipc call search toggle`.
    IpcHandler {
        target: "search"

        function toggle(): void {
            searchPanel.toggle();
        }
    }

    // Alt+Tab and Alt+Shift+Tab (config/labwc/rc.xml):
    // `qs ipc call switcher next`.
    IpcHandler {
        target: "switcher"

        function next(): void {
            switcher.step(1);
        }

        function previous(): void {
            switcher.step(-1);
        }
    }

    // `qs ipc call updates toggle`.
    IpcHandler {
        target: "updates"

        function toggle(): void {
            updatesPanel.toggle();
        }
    }

    // The agents' hooks (bin/puter-agent hook):
    // `qs ipc call agents set "Claude · puter" working`.
    IpcHandler {
        target: "agents"

        function set(title: string, state: string): void {
            bar.setAgent(title, state);
        }
    }
}
