/*
 *  rebooter.c - CLIP reboot menu
 *  Copyright (C) 2008 SGDN
 *  Author: Vincent Strubel <clipos@ssi.gouv.fr>
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License version
 *  2 as published by the Free Software Foundation.
 *
 */

#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <errno.h>
#include <gtk/gtk.h>

#define _U __attribute__((unused))
#define NUM_BUTTONS 2

#define XDIALOG "/usr/local/bin/Xdialog"

#define BEGIN_CHILD_PROTECT() do {\
  sigemptyset(&set); \
  sigaddset(&set, SIGCHLD); \
  sigprocmask(SIG_BLOCK, &set, &oldset); \
} while (0)

#define END_CHILD_PROTECT() do {\
  sigemptyset(&set); \
  sigaddset(&set, SIGCHLD); \
  sigprocmask(SIG_UNBLOCK, &set, &oldset); \
} while (0)

#define ERROR(fmt, args...) fprintf(stderr, fmt, ##args)

typedef struct {
	GPid pid;
	const char *label;
	char *cmd;
	const char *msg;
	GtkWidget *widget;
} button_t;


static button_t buttons[NUM_BUTTONS];

static const char *const labels[NUM_BUTTONS] = {
	"Arrêter",
	"Redémarrer"
};

static const char *const messages[NUM_BUTTONS] = {
	"Arrêter le poste ?",
	"Redémarrer le poste ?"
};

static char *const commands[NUM_BUTTONS] = {
	"/sbin/halt",
	"/sbin/reboot"
};

static int 
confirm(const char *msg)
{
	gchar *argv[] = {
		XDIALOG, "--ok-label", "Oui", "--cancel-label", "Non", 
		"--yesno", msg, "6", "40", NULL
	};

	gint status;
	GError *err = NULL;
	gboolean ret;

	ret = g_spawn_sync(NULL, argv, NULL, 0, NULL, 
				NULL, NULL, NULL, &status, &err);
	if (ret == TRUE) {
		if (WIFEXITED(status) && !WEXITSTATUS(status))
			return 1;
		return 0;
	} else {
		if (err != NULL)
			ERROR("Spawn error %s\n", err->message);
		else
			ERROR("Spawn error, no message\n");

		return 0;
	}
}

static void
child_reaper(GPid pid, gint status _U, gpointer data)
{
	button_t *button = data;
	if (pid == button->pid) {
		button->pid = 0;
		gtk_widget_set_sensitive(button->widget, TRUE);
	} else {
		ERROR("child_reaper error on %s: %d != %d\n", 
				button->label, pid, button->pid);
	}
}

static void
button_callback(GtkWidget *widget _U, gpointer data)
{
	GPid pid;
	sigset_t set, oldset;
	button_t *button = data;
	gboolean ret = FALSE;
	GError *err = NULL;
	char *argv[] = {
		button->cmd,
		NULL
	};


	if (!confirm(button->msg))
		return;

	BEGIN_CHILD_PROTECT();
	if (button->pid) {
		ERROR("Button %s is already active\n", button->label);
		goto out;
	}
	ret = g_spawn_async(NULL, argv, NULL, G_SPAWN_DO_NOT_REAP_CHILD,
				NULL, NULL, &pid, &err);
	if (ret == TRUE) {
		button->pid = pid;
		(void)g_child_watch_add(pid, child_reaper, button);
		gtk_widget_set_sensitive(button->widget, FALSE);
	} else {
		if (err != NULL)
			ERROR("Spawn error %s\n", err->message);
		else
			ERROR("Spawn error, no message\n");
	}
out:
	END_CHILD_PROTECT();
}

static void
destroy(GtkWidget *widget _U, gpointer data _U)
{
	gtk_main_quit();
}

int
main(int argc, char *argv[])
{
	GtkWidget *window, *hbox;
	int i;
	gint w, h, sw, sh;

	gtk_init(&argc, &argv);

	window = gtk_window_new(GTK_WINDOW_TOPLEVEL);

	g_signal_connect(G_OBJECT(window), "destroy",
			G_CALLBACK(destroy), NULL);
	gtk_container_set_border_width(GTK_CONTAINER(window), 0);

	hbox = gtk_hbox_new(TRUE, 0);

	for (i = 0; i < NUM_BUTTONS; i++) {
		GtkWidget *button = gtk_button_new_with_label(labels[i]);
		GtkWidget *label = gtk_bin_get_child(GTK_BIN(button));

		gtk_widget_modify_font(label, 
			pango_font_description_from_string(
				"Bitstream Vera Sans Bold 12"));

		buttons[i].widget = button;
		buttons[i].label = labels[i];
		buttons[i].cmd = commands[i];
		buttons[i].msg = messages[i];
		buttons[i].pid = 0;

		g_signal_connect(G_OBJECT(button), "clicked", 
				G_CALLBACK(button_callback), buttons + i);

		gtk_box_pack_start(GTK_BOX(hbox), button, TRUE, TRUE, 0);
		gtk_widget_show(button);
	}

	gtk_container_add(GTK_CONTAINER(window), hbox);
	
	gtk_widget_show(hbox);

	sw = gdk_screen_width();
	sh = gdk_screen_height();
	gtk_window_get_size(window, &w, &h);

	gtk_window_move(window, sw - ((sw + w) / 2), sh - 100);
	gtk_widget_show(window);

	gtk_main();

	return 0;
}
	
	
