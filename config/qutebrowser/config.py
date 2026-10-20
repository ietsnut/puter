# qutebrowser, puter's web browser: only the page, a tab bar above it when
# there's more than one tab, and the status bar below it with the address
# (type o to go somewhere, : for commands). Every bar is one module, words one inset in.
# The colours and fonts are theme/qutebrowser/puter.py, from the palette.
# Settings made in the browser aren't kept (no autoconfig): this file is all.
config.load_autoconfig(False)
config.source("puter.py")

c.tabs.show = "multiple"
c.tabs.position = "top"
c.tabs.favicons.show = "never"
c.tabs.indicator.width = 0
c.tabs.title.format = "{current_title}"
c.tabs.title.alignment = "left"
# Tabs whole modules wide: eight each, however many there are.
c.tabs.min_width = 240
c.tabs.max_width = 240
c.tabs.padding = {"top": 5, "bottom": 5, "left": 8, "right": 8}

c.statusbar.show = "always"
c.statusbar.position = "bottom"
c.statusbar.widgets = ["keypress", "url", "progress"]
c.statusbar.padding = {"top": 5, "bottom": 5, "left": 8, "right": 8}

c.downloads.position = "bottom"
c.scrolling.bar = "never"
c.completion.scrollbar.width = 0
c.completion.scrollbar.padding = 0
c.completion.shrink = True

c.url.start_pages = ["about:blank"]
c.url.default_page = "about:blank"
c.window.title_format = "{current_title}"
c.content.prefers_reduced_motion = True
