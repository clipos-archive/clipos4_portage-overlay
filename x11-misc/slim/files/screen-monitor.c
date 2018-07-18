/*
 *  screen-monitor.c - CLIP screen monitor
 *  Copyright (C) 2010 ANSSI
 *  Author: Vincent Strubel <clipos@ssi.gouv.fr>
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License version
 *  2 as published by the Free Software Foundation.
 *
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <gtk/gtk.h>
#include <gdk/gdk.h>

#define SIZE_CHANGED_CMD PREFIX"/bin/screen-size-changed.sh"

static GdkScreen *screen = NULL;

static gboolean verbose = FALSE;

static void
screen_changed_handler(GtkWidget *widget)
{
	gint w, h, wt, ht, i, num;
	char total_width[5];
	char total_height[5];
	char width[5];
	char height[5];
	GdkRectangle rect;
	gchar *name;

	gchar *argv[] = { SIZE_CHANGED_CMD, 
		total_width, total_height, width, height, NULL };
	gint status;
	gboolean ret;
	GError *err = NULL;

	w = gdk_screen_get_width(screen);
	h = gdk_screen_get_height(screen);
	if (verbose)
		printf("screen geom: %d x %d\n", w, h);
	/* Total screen width / height, used to chose wallpaper for example */
	wt = w;
	ht = h;

	/* Get main display geometry (could be smaller than total screen size),
	 * use it as reference for e.g. viewer size, so a viewer can fit
	 * entirely on that display.
	 */

	num = gdk_screen_get_n_monitors(screen);
		
	for (i = 0; i < num; i++) {
		name = gdk_screen_get_monitor_plug_name(screen, i);
		gdk_screen_get_monitor_geometry(screen, i, &rect);
		if (verbose)
			printf("monitor %s geom: %d x %d\n", name, rect.width, rect.height);
		
		/*
		Also DP1, etc...
		if (strcmp(name, "LVDS1") && strcmp(name, "VGA1") && strcmp(name, "DVI1"))
			continue;
		*/
		
		if (rect.width < w)
			w = rect.width;
		if (rect.height < h)
			h = rect.height;
	}

	if (verbose)
		printf("final geom: %dx%d\n", w, h);

	if (w > 9999 || h > 9999 || wt > 9999 || ht > 9999) {
		fprintf(stderr, "unsupported screen size: %dx%d\n", w, h);
		return;
	}

	snprintf(total_width, sizeof(total_width), "%d", wt);
	snprintf(total_height, sizeof(total_height), "%d", ht);
	snprintf(width, sizeof(width), "%d", w);
	snprintf(height, sizeof(height), "%d", h);
	
	ret = g_spawn_sync(NULL, argv, NULL, 0, NULL, 
				NULL, NULL, NULL, &status, &err);
	
	if (ret != TRUE) {
		if (err != NULL)
			fprintf(stderr, "spawn error %s\n", err->message);
		else
			fputs("spawn error, no message\n", stderr);
	}
}

int 
main(int argc, char **argv)
{
	gtk_init(&argc, &argv);

	if (argc > 1 && !strcmp(argv[1], "-v"))
		verbose = TRUE;

	GdkDisplay *disp = gdk_display_open(getenv("DISPLAY"));
	if (!disp) {
		fputs("no display\n", stderr);
		return EXIT_FAILURE;
	}
	screen = gdk_screen_get_default();

	if (!screen) {
		fputs("no screen\n", stderr);
		return EXIT_FAILURE;
	}

	g_signal_connect(G_OBJECT(screen), "size-changed",
		G_CALLBACK(screen_changed_handler), NULL);

	g_signal_connect(G_OBJECT(screen), "monitors-changed",
		G_CALLBACK(screen_changed_handler), NULL);

	gtk_main();
	return EXIT_FAILURE;
}
