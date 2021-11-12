/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Widgets.ProjectRow : Gtk.ListBoxRow {
    public Objects.Project project { get; construct; }

    private Gtk.Label name_label;
    private Gtk.Revealer main_revealer;
    private Widgets.ProjectProgress project_progress;
    private Gtk.ListBox listbox;
    private Gtk.Revealer listbox_revealer;
    private Gtk.Grid handle_grid;
    private Gtk.EventBox projectrow_eventbox;
    private Gtk.Button arrow_button;
    private Gtk.Label count_label;
    private Gtk.Revealer count_revealer;
    private Gtk.Revealer top_motion_revealer;
    private Gtk.Revealer bottom_motion_revealer;

    private bool has_subprojects {
        get {
            return listbox.get_children ().length () > 0;
        }
    }

    private const Gtk.TargetEntry[] TARGET_ENTRY_PROJECTROW = {
        {"PROJECTROW", Gtk.TargetFlags.SAME_APP, 0}
    };
    
    public ProjectRow (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        get_style_context ().add_class ("selectable-item");
        
        project_progress = new Widgets.ProjectProgress (18);
        project_progress.enable_subprojects = true;
        project_progress.valign = Gtk.Align.CENTER;
        project_progress.halign = Gtk.Align.CENTER;
        project_progress.progress_fill_color = Util.get_default ().get_color (project.color);

        name_label = new Gtk.Label (project.name);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        
        count_label = new Gtk.Label ("3") {
            hexpand = true,
            halign = Gtk.Align.END,
            margin_end = 3
        };
        count_label.get_style_context ().add_class ("dim-label");
        count_label.get_style_context ().add_class ("small-label");

        count_revealer = new Gtk.Revealer () {
            reveal_child = true
        };
        count_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        count_revealer.add (count_label);

        var arrow_icon = new Gtk.Image ();
        arrow_icon.gicon = new ThemedIcon ("pan-end-symbolic");
        arrow_icon.pixel_size = 14;

        arrow_button = new Gtk.Button ();
        arrow_button.valign = Gtk.Align.CENTER;
        arrow_button.halign = Gtk.Align.END;
        arrow_button.can_focus = false;
        arrow_button.image = arrow_icon;
        arrow_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        arrow_button.get_style_context ().add_class ("dim-label");
        arrow_button.get_style_context ().add_class ("transparent");
        arrow_button.get_style_context ().add_class ("hidden-button");
        arrow_button.get_style_context ().add_class ("no-padding");

        var menu_stack = new Gtk.Stack ();
        menu_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        menu_stack.homogeneous = true;

        var due_label = new Gtk.Label (null);
        due_label.use_markup = true;
        due_label.valign = Gtk.Align.CENTER;
        due_label.get_style_context ().add_class ("pane-due-button");

        if (project.due_date != "") {
            menu_stack.add_named (due_label, "due_label");
            menu_stack.add_named (count_revealer, "count_revealer");
            menu_stack.add_named (arrow_button, "arrow_button");
        } else {
            menu_stack.add_named (count_revealer, "count_revealer");
            menu_stack.add_named (arrow_button, "arrow_button");
            menu_stack.add_named (due_label, "due_label");
        }

        var projectrow_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin = 3
        };
        projectrow_grid.add (project_progress);
        projectrow_grid.add (name_label);
        projectrow_grid.add (menu_stack);

        handle_grid = new Gtk.Grid ();
        handle_grid.add (projectrow_grid);

        projectrow_eventbox = new Gtk.EventBox () {
            
        };
        projectrow_eventbox.get_style_context ().add_class ("transition");
        projectrow_eventbox.add (handle_grid);

        listbox = new Gtk.ListBox () {
            hexpand = true
        };

        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("pane-listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_start = 12,
            margin_top = 6
        };
        listbox_grid.add (listbox);

        listbox_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        listbox_revealer.add (listbox_grid);

        var top_motion_grid = new Gtk.Grid ();
        top_motion_grid.get_style_context ().add_class ("grid-motion");
        top_motion_grid.height_request = 16;

        top_motion_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        top_motion_revealer.add (top_motion_grid);

        var bottom_motion_grid = new Gtk.Grid ();
        bottom_motion_grid.get_style_context ().add_class ("grid-motion");
        bottom_motion_grid.height_request = 16;

        bottom_motion_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        bottom_motion_revealer.add (bottom_motion_grid);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };
        main_grid.add (top_motion_revealer);
        main_grid.add (projectrow_eventbox);
        main_grid.add (bottom_motion_revealer);
        main_grid.add (listbox_revealer);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.add (main_grid);

        add (main_revealer);
        
        update_request ();
        build_drag_and_drop ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        project.updated.connect (() => {
            update_request ();
        });

        listbox.add.connect (() => {
            project_progress.has_subprojects = has_subprojects;
            listbox_revealer.reveal_child = has_subprojects;
        });

        listbox.remove.connect (() => {
            project_progress.has_subprojects = has_subprojects;
            listbox_revealer.reveal_child = has_subprojects;
        });

        projectrow_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                Timeout.add (120, () => {
                    if (main_revealer.reveal_child) {
                        Planner.event_bus.pane_selected (PaneType.PROJECT, project.id_string);
                    }
                    return GLib.Source.REMOVE;
                });
            } else if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                // activate_menu ();
            }

            return Gdk.EVENT_PROPAGATE;
        });

        Planner.event_bus.pane_selected.connect ((pane_type, id) => {
            if (pane_type == PaneType.PROJECT && project.id_string == id) {
                projectrow_eventbox.get_style_context ().add_class ("selectable-item-selected");
            } else {
                projectrow_eventbox.get_style_context ().remove_class ("selectable-item-selected");
            }
        });

        projectrow_eventbox.enter_notify_event.connect ((event) => {
            if (has_subprojects) {
                menu_stack.visible_child_name = "arrow_button";
                return true;
            }
        });

        projectrow_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            if (project.due_date == "") {
                menu_stack.visible_child_name = "count_revealer";
            } else {
                menu_stack.visible_child_name = "due_label";
            }

            return true;
        });

        arrow_button.clicked.connect (() => {
            listbox_revealer.reveal_child = !listbox_revealer.reveal_child;
            update_listbox_revealer ();
            project.update ();
        });
    }

    private void update_listbox_revealer () {
        if (listbox_revealer.reveal_child) {
            project.collapsed = 1;
            arrow_button.get_style_context ().remove_class ("opened");
        } else {
            arrow_button.get_style_context ().add_class ("opened");
            project.collapsed = 0;
        }
    }

     public void update_request () {
        name_label.label = project.name;
        project_progress.progress_fill_color = Util.get_default ().get_color (project.color);
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }

    public void add_subproject (Widgets.ProjectRow row) {
        listbox.add (row);
        listbox.show_all ();
    }

    private void build_drag_and_drop () {
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, TARGET_ENTRY_PROJECTROW, Gdk.DragAction.MOVE);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);

        Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, TARGET_ENTRY_PROJECTROW, Gdk.DragAction.MOVE);
        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);
        drag_data_received.connect (on_drag_data_received);
        drag_end.connect (clear_indicator);
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = ((Widgets.ProjectRow) widget).handle_grid;

        Gtk.Allocation row_alloc;
        row.get_allocation (out row_alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, row_alloc.width, row_alloc.height);
        var cairo_context = new Cairo.Context (surface);

        var style_context = row.get_style_context ();
        style_context.add_class ("drag-begin");
        row.draw_to_cairo_context (cairo_context);
        style_context.remove_class ("drag-begin");

        int drag_icon_x, drag_icon_y;
        widget.translate_coordinates (row, 0, 0, out drag_icon_x, out drag_icon_y);
        surface.set_device_offset (-drag_icon_x, -drag_icon_y);

        Gtk.drag_set_icon_surface (context, surface);
        main_revealer.reveal_child = false;
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (Widgets.ProjectRow))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("PROJECTROW"), 32, data
        );
    }

    public void clear_indicator (Gdk.DragContext context) {
        main_revealer.reveal_child = true;
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {

        var data = ((Gtk.Widget[]) selection_data.get_data ()) [0];
        var source_row = (Widgets.ProjectRow) data;
        var target_row = this;
        Gtk.Allocation alloc;
        target_row.get_allocation (out alloc);

        if (source_row == target_row || target_row == null) {
            return;
        }

        var source_list = (Gtk.ListBox) source_row.parent;
        var target_list = (Gtk.ListBox) target_row.parent;

        source_list.remove (source_row);

        if (target_row.get_index () == 0) {
            if (y < (alloc.height / 2)) {
                target_list.insert (source_row, 0);
            } else {
                target_list.insert (source_row, target_row.get_index () + 1);
            }
        } else {
            target_list.insert (source_row, target_row.get_index () + 1);
        }
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        Gtk.Allocation alloc;
        projectrow_eventbox.get_allocation (out alloc);
        
        if (get_index () == 0) {
            if (y > (alloc.height / 2)) {
                bottom_motion_revealer.reveal_child = true;
                top_motion_revealer.reveal_child = false;
            } else {
                bottom_motion_revealer.reveal_child = false;
                top_motion_revealer.reveal_child = true;
            }
        } else {
            bottom_motion_revealer.reveal_child = true;
        }

        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        bottom_motion_revealer.reveal_child = false;
        top_motion_revealer.reveal_child = false;
    }
}
