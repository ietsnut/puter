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

    // Super+Space: `qs ipc call search toggle`.
    IpcHandler {
        target: "search"

        function toggle(): void {
            searchPanel.toggle();
        }
    }
}
