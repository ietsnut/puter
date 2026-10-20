import Quickshell

ShellRoot {
    Desk {}

    // The search square opens fuzzel, or closes it if it is already open.
    Bar {
        onSearch: Quickshell.execDetached(["sh", "-c", "pkill -x fuzzel || fuzzel"])
    }
}
