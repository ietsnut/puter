import Quickshell
import Quickshell.Io

ShellRoot {
    Desk {}

    Bar {
        onSearch: {
            settingsPanel.visible = false;
            searchPanel.toggle();
        }
        onSettings: {
            searchPanel.visible = false;
            settingsPanel.toggle();
        }
    }

    Dismiss {
        visible: searchPanel.visible || settingsPanel.visible
        onClicked: {
            searchPanel.visible = false;
            settingsPanel.visible = false;
        }
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
            settingsPanel.visible = false;
            searchPanel.toggle();
        }
    }

    IpcHandler {
        target: "settings"

        function toggle(): void {
            searchPanel.visible = false;
            settingsPanel.toggle();
        }
    }
}
