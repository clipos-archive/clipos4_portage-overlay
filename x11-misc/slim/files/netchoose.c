/*
 *  netchoose.c - CLIP network profile selector
 *  Copyright (C) 2010 ANSSI
 *  Author: Mickaẽl Salaün <clipos@ssi.gouv.fr>
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License version
 *  2 as published by the Free Software Foundation.
 */

#include <gtk/gtk.h>
#include <errno.h>
#include <string.h>

#define _U __attribute__((unused))
#define ERROR(...) fprintf(stderr, __VA_ARGS__)
//#define DEBUG(...) fprintf(stderr, "DEBUG: " __VA_ARGS__)
#define DEBUG(...) { /* */ }

#define PROFILE_LIST_FILE "/usr/local/var/net_list"
#define PROFILE_CHOOSE_FILE "/usr/local/var/net_choice"
#define WINDOW_FONT "Bitstream Vera Sans Bold 12"
#define WINDOW_WIDTH 240
#define WINDOW_HEIGHT 130
#define WINDOW_VERTICAL 120

static gboolean profile_list_get(gchar ***pflist) {
	gsize size = 0;
	gboolean ret;
	gchar *buf = NULL;
	GError *err = NULL;

	*pflist = NULL;
	ret = g_file_get_contents(PROFILE_LIST_FILE, &buf, &size, &err);
	if(ret && size != 0) {
		if(buf[size - 1] == '\n') {
			buf[size - 1] = '\0';
		}
		*pflist = g_strsplit(buf, "\n", 0);
		g_free(buf);
		return TRUE;
	} else {
		if(err) {
			ERROR("Unable to get profile list: %s\n", err->message);
		} else {
			ERROR("Unable to get profile list\n");
		}
	}
	return FALSE;
}

static gboolean profile_choice_get(gchar **pfchoice) {
	gsize size = 0;
	gboolean ret;
	gchar *buf = NULL;
	GError *err = NULL;

	*pfchoice = NULL;
	ret = g_file_get_contents(PROFILE_CHOOSE_FILE, &buf, &size, &err);
	if(ret && size != 0) {
		if(buf[size - 1] == '\n') {
			buf[size - 1] = '\0';
		}
		*pfchoice = g_strdup(buf);
		g_free(buf);
		return TRUE;
	} else {
		if(err) {
			ERROR("Unable to get profile choice: %s\n", err->message);
		} else {
			ERROR("Unable to get profile choice\n");
		}
	}
	return FALSE;
}

static void profile_choose(GtkTreeView *wid, gpointer tree)
{
	GtkTreeModel *model = NULL;
	GtkTreeIter iter;
	GtkTreeSelection *selection = NULL;
	gchar *profile = NULL;
	gboolean ret;
	GError *err = NULL;
 
	selection = gtk_tree_view_get_selection(tree);
	gtk_tree_selection_set_mode(selection, GTK_SELECTION_SINGLE);
	if(gtk_tree_selection_get_selected(selection, &model, &iter)) {
		gtk_tree_model_get(model, &iter, 0, &profile, -1);
	}
	DEBUG("profile: %s\n", profile);
	ret = g_file_set_contents(PROFILE_CHOOSE_FILE, profile, strlen(profile), &err);
	if(!ret) {
		if(err) {
			ERROR("Unable to set profile: %s\n", err->message);
		} else {
			ERROR("Unable to set profile\n");
		}
	}
	(void)wid;
}

static void destroy(GtkWidget *widget _U, gpointer data _U)
{
	gtk_main_quit();
}

int main(int argc, gchar **argv)
{
	guint i = 0;
	gint sw, sh, defi = -1;
	gchar **pflist = NULL, *pfchoice = NULL;
	GtkListStore *store = NULL;
	GtkCellRenderer *cell = NULL;
	GtkTreeIter iter;
	GtkTreeSelection *select = NULL;
	GtkTreePath *path = NULL;
	GtkWidget *win = NULL, *vbox = NULL, *tree = NULL, *label = NULL, *scroll = NULL;

	gtk_init(&argc, &argv);

	win = gtk_window_new(GTK_WINDOW_TOPLEVEL);
	gtk_window_set_title(GTK_WINDOW(win), "Choix du profil réseau");
	gtk_widget_set_size_request(win, WINDOW_WIDTH, WINDOW_HEIGHT);
	g_signal_connect(G_OBJECT(win), "destroy", G_CALLBACK(destroy), NULL);

	vbox = gtk_vbox_new(FALSE, 5);
	gtk_container_add(GTK_CONTAINER(win), vbox);

	label = gtk_label_new("Profil réseau : ");
	gtk_widget_modify_font(label, pango_font_description_from_string(WINDOW_FONT));
	gtk_label_set_justify(GTK_LABEL(label), GTK_JUSTIFY_CENTER);
	gtk_box_pack_start(GTK_BOX(vbox), label, TRUE, TRUE, 0);

	store = gtk_list_store_new(1, G_TYPE_STRING);
	if(!profile_list_get(&pflist) || !profile_choice_get(&pfchoice)) {
		return 1;
	}
	DEBUG("init choice: %s\n", pfchoice);
	for(i = 0; i < g_strv_length(pflist); i++) {
		DEBUG("%d: %s\n", i, pflist[i]);
		gtk_list_store_append(store, &iter);
		gtk_list_store_set(store, &iter, 0, pflist[i], -1);
		if(g_strcmp0(pfchoice, pflist[i]) == 0) {
			DEBUG("-> got it\n");
			defi = i;
		}
	}
	if(defi == -1) {
		defi = 0;
	}

	tree = gtk_tree_view_new();
	cell = gtk_cell_renderer_text_new();
	gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(tree), -1, NULL, cell, "text", 0, NULL);
	gtk_tree_view_set_headers_visible(GTK_TREE_VIEW(tree), FALSE);
	gtk_tree_view_set_model(GTK_TREE_VIEW(tree), GTK_TREE_MODEL(store));
	select = gtk_tree_view_get_selection(GTK_TREE_VIEW(tree));
	path = gtk_tree_path_new_from_indices(defi, -1);
	gtk_tree_selection_select_path(select, path);
	gtk_tree_path_free(path);
	g_signal_connect(G_OBJECT(tree), "cursor-changed", G_CALLBACK(profile_choose), tree);

	scroll = gtk_scrolled_window_new(NULL, NULL);
	gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scroll), GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
	gtk_widget_set_size_request(scroll, 0, WINDOW_HEIGHT - 30);
	gtk_container_add(GTK_CONTAINER(scroll), tree);
	gtk_box_pack_start(GTK_BOX(vbox), scroll, TRUE, TRUE, 0);

	sw = gdk_screen_width();
	sh = gdk_screen_height();
	gtk_window_move(GTK_WINDOW(win), sw - ((sw + WINDOW_WIDTH) / 2), sh - WINDOW_HEIGHT - WINDOW_VERTICAL);
	gtk_widget_show_all(win);
	gtk_main();
	return 0;
}
