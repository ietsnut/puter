import Quickshell
import Quickshell.Io

ShellRoot {
    Desk {}

    Bar {
        updates: updatesPanel.barState
        onSearch: searchPanel.toggle()
        onUpdate: updatesPanel.toggle()
    }

    Dismiss {
        visible: searchPanel.visible
        onClicked: searchPanel.visible = false
    }

    SearchPanel {
        id: searchPanel
    }

    Dismiss {
        visible: updatesPanel.visible
        onClicked: updatesPanel.visible = false
    }

    Updates {
        id: updatesPanel
    }

    Toasts {}

    // Super+Space: `qs ipc call search toggle`.
    IpcHandler {
        target: "search"

        function toggle(): void {
            searchPanel.toggle();
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
            Agents.set(title, state);
        }
    }
}
