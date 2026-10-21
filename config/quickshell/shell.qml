import Quickshell
import Quickshell.Io

ShellRoot {
    Desk {}

    Bar {
        onSearch: searchPanel.toggle()
    }

    Dismiss {
        visible: searchPanel.visible
        onClicked: searchPanel.visible = false
    }

    SearchPanel {
        id: searchPanel
    }

    Toasts {}

    // Super+Space: `qs ipc call search toggle`.
    IpcHandler {
        target: "search"

        function toggle(): void {
            searchPanel.toggle();
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
