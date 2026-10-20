import Quickshell
import Quickshell.Io

ShellRoot {
    Desk {}

    Bar {
        onSearch: searchPanel.toggle()
        onSettings: settingsPanel.toggle()
    }

    SearchPanel {
        id: searchPanel
    }

    SettingsPanel {
        id: settingsPanel
    }

    // Super+Space: `qs ipc call search toggle`; `qs ipc call settings toggle`.
    IpcHandler {
        target: "search"

        function toggle(): void {
            searchPanel.toggle();
        }
    }

    IpcHandler {
        target: "settings"

        function toggle(): void {
            settingsPanel.toggle();
        }
    }
}
