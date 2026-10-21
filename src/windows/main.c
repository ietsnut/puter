// puter-windows: the open windows, a line each: the identifier labwc gives
// it in ext-foreign-toplevel-list (what `grim -T` captures), its app ID and
// its title, between tabs. The switcher (config/quickshell/Switcher.qml)
// matches these to its own windows to take their previews.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wayland-client.h>
#include "ext-foreign-toplevel-list-v1-client-protocol.h"

struct window {
	char *identifier, *app_id, *title;
	struct window *next;
};

static struct ext_foreign_toplevel_list_v1 *list;
static struct window *windows, **last = &windows;

static void replace(char **field, const char *value) {
	free(*field);
	*field = strdup(value);
}

static void handle_closed(void *data, struct ext_foreign_toplevel_handle_v1 *handle) {}
static void handle_done(void *data, struct ext_foreign_toplevel_handle_v1 *handle) {}
static void handle_title(void *data, struct ext_foreign_toplevel_handle_v1 *handle, const char *title) {
	replace(&((struct window *)data)->title, title);
}
static void handle_app_id(void *data, struct ext_foreign_toplevel_handle_v1 *handle, const char *app_id) {
	replace(&((struct window *)data)->app_id, app_id);
}
static void handle_identifier(void *data, struct ext_foreign_toplevel_handle_v1 *handle, const char *identifier) {
	replace(&((struct window *)data)->identifier, identifier);
}

static const struct ext_foreign_toplevel_handle_v1_listener handle_listener = {
	.closed = handle_closed,
	.done = handle_done,
	.title = handle_title,
	.app_id = handle_app_id,
	.identifier = handle_identifier,
};

static void list_toplevel(void *data, struct ext_foreign_toplevel_list_v1 *list,
		struct ext_foreign_toplevel_handle_v1 *handle) {
	struct window *window = calloc(1, sizeof *window);
	*last = window;
	last = &window->next;
	ext_foreign_toplevel_handle_v1_add_listener(handle, &handle_listener, window);
}
static void list_finished(void *data, struct ext_foreign_toplevel_list_v1 *list) {}

static const struct ext_foreign_toplevel_list_v1_listener list_listener = {
	.toplevel = list_toplevel,
	.finished = list_finished,
};

static void global(void *data, struct wl_registry *registry, uint32_t name, const char *interface, uint32_t version) {
	if (strcmp(interface, ext_foreign_toplevel_list_v1_interface.name) == 0) {
		list = wl_registry_bind(registry, name, &ext_foreign_toplevel_list_v1_interface, 1);
		ext_foreign_toplevel_list_v1_add_listener(list, &list_listener, NULL);
	}
}
static void global_remove(void *data, struct wl_registry *registry, uint32_t name) {}

static const struct wl_registry_listener registry_listener = {
	.global = global,
	.global_remove = global_remove,
};

// Tabs and line breaks in a title would break the line apart.
static void print_field(const char *value) {
	for (const char *c = value ? value : ""; *c; c++)
		putchar(*c == '\t' || *c == '\n' ? ' ' : *c);
}

int main(void) {
	struct wl_display *display = wl_display_connect(NULL);
	if (!display) {
		fprintf(stderr, "puter-windows: no Wayland display\n");
		return 1;
	}
	struct wl_registry *registry = wl_display_get_registry(display);
	wl_registry_add_listener(registry, &registry_listener, NULL);
	wl_display_roundtrip(display);
	if (!list) {
		fprintf(stderr, "puter-windows: the compositor has no ext-foreign-toplevel-list\n");
		return 1;
	}
	// One round trip for the windows, one for what each one is.
	wl_display_roundtrip(display);
	wl_display_roundtrip(display);
	for (struct window *window = windows; window; window = window->next) {
		print_field(window->identifier);
		putchar('\t');
		print_field(window->app_id);
		putchar('\t');
		print_field(window->title);
		putchar('\n');
	}
	wl_display_disconnect(display);
	return 0;
}
