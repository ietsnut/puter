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
        onNetwork: networkPanel.toggle()
        onLock: lockScreen.lock()
    }

    Dismiss {
        visible: updatesPanel.visible || volumePanel.visible || networkPanel.visible
        onClicked: {
            updatesPanel.visible = false;
            volumePanel.visible = false;
            networkPanel.visible = false;
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

    Network {
        id: networkPanel
        implicitWidth: bar.statusWidth
    }

    Toasts {}

    Switcher {
        id: switcher
    }

    Lock {
        id: lockScreen
    }

    // The bar's lock button: `qs ipc call lock lock`. And from SSH, if the
    // code's forgotten: `qs ipc call lock unlock`.
    IpcHandler {
        target: "lock"

        function lock(): void {
            lockScreen.lock();
        }

        function unlock(): void {
            lockScreen.unlock();
        }
    }

    // Super+Space: `qs ipc call search toggle`.
    IpcHandler {
        target: "search"

        function toggle(): void {
            if (!searchPanel.shown)
                bar.turn();
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

    // `qs ipc call network toggle`.
    IpcHandler {
        target: "network"

        function toggle(): void {
            networkPanel.toggle();
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
