import Quickshell

ShellRoot {
    Desk {}

    Bar {
        onSearch: searchPanel.toggle()
    }

    SearchPanel {
        id: searchPanel
    }
}
