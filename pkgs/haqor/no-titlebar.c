// SPDX-License-Identifier: MIT
//
// The stock Flutter Linux runner hands the window a GtkHeaderBar unless it is
// on X11 under a window manager other than GNOME Shell, so under sway/niri it
// grows a client-side title bar that the compositor cannot remove. Preloading
// this shim in front of GTK turns that call into "no decorations at all".
#include <gtk/gtk.h>

void gtk_window_set_titlebar(GtkWindow *window, GtkWidget *titlebar) {
  (void)titlebar;
  gtk_window_set_decorated(window, FALSE);
}
