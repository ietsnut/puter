// puter-windows: the open windows, a line each: the identifier labwc gives
// it in ext-foreign-toplevel-list (what `grim -T` captures), its app ID and
// its title, between tabs. The switcher (config/quickshell/Switcher.qml)
// matches these to its own windows to take their previews.
//
// puter-windows trim FILE.ppm...: cuts off the pure black a capture can
// have around its window. labwc captures everything a window has, and some
// apps keep a surface outside the window itself (Firefox, above and left of
// it), so the capture is larger and the rest is filled with black, #000000,
// which no window's whole edge is (puter's darkest ink is #060606).
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

// A binary PPM (P6, 8 bits, as grim writes it), cropped in place to the
// smallest box whose every edge row and column has something not pure black.
static int trim(const char *path) {
	FILE *file = fopen(path, "rb");
	if (!file)
		return 1;
	int width, height, max;
	if (fscanf(file, "P6 %d %d %d", &width, &height, &max) != 3 || max != 255 || fgetc(file) == EOF ||
			width <= 0 || height <= 0) {
		fclose(file);
		return 1;
	}
	size_t stride = (size_t)width * 3;
	unsigned char *pixels = malloc(stride * height);
	if (!pixels || fread(pixels, stride, height, file) != (size_t)height) {
		free(pixels);
		fclose(file);
		return 1;
	}
	fclose(file);

	#define BLACK(x, y) (!pixels[(y) * stride + (x) * 3] && !pixels[(y) * stride + (x) * 3 + 1] && \
		!pixels[(y) * stride + (x) * 3 + 2])
	int top = 0, bottom = height - 1, left = 0, right = width - 1, x, y;
	for (; top <= bottom; top++) {
		for (x = 0; x < width && BLACK(x, top); x++) {}
		if (x < width)
			break;
	}
	for (; bottom > top; bottom--) {
		for (x = 0; x < width && BLACK(x, bottom); x++) {}
		if (x < width)
			break;
	}
	for (; left <= right; left++) {
		for (y = top; y <= bottom && BLACK(left, y); y++) {}
		if (y <= bottom)
			break;
	}
	for (; right > left; right--) {
		for (y = top; y <= bottom && BLACK(right, y); y++) {}
		if (y <= bottom)
			break;
	}
	// All black (a window not drawn yet), or nothing to cut: as it is.
	if (top > bottom || left > right || (top == 0 && left == 0 && bottom == height - 1 && right == width - 1)) {
		free(pixels);
		return 0;
	}
	// Written beside it and moved over it, so it's never read half-written.
	char temporary[4096];
	snprintf(temporary, sizeof temporary, "%s.trim", path);
	file = fopen(temporary, "wb");
	if (!file) {
		free(pixels);
		return 1;
	}
	fprintf(file, "P6\n%d %d\n255\n", right - left + 1, bottom - top + 1);
	for (y = top; y <= bottom; y++)
		fwrite(pixels + y * stride + left * 3, 3, right - left + 1, file);
	free(pixels);
	if (fclose(file) != 0)
		return 1;
	return rename(temporary, path) != 0;
}

int main(int argc, char **argv) {
	if (argc > 1 && strcmp(argv[1], "trim") == 0) {
		int failed = 0;
		for (int i = 2; i < argc; i++)
			failed |= trim(argv[i]);
		return failed;
	}

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
