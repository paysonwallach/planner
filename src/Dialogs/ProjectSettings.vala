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

public class Dialogs.ProjectSettings : Gtk.Dialog {
    public Objects.Project project { get; construct; }
    private Widgets.Entry name_entry;
    private Widgets.TextView description_textview;
    private Gtk.ListStore color_liststore;
    private Gtk.ComboBox color_combobox;
    private Gtk.Switch due_switch;
    private Granite.Widgets.DatePicker due_datepicker;
    private Gtk.Revealer due_revealer;

    public ProjectSettings (Objects.Project project) {
        Object (
            project: project,
            transient_for: Planner.instance.main_window,
            deletable: false,
            resizable: true,
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: false,
            title: _("Project Settings")
        );
    }

    construct {
        height_request = 550;
        width_request = 480;
        get_style_context ().add_class ("planner-dialog");
        
        name_entry = new Widgets.Entry ();
        name_entry.margin_start = 12;
        name_entry.margin_end = 12;
        name_entry.text = project.name;
        name_entry.get_style_context ().add_class ("border-radius-4");

        description_textview = new Widgets.TextView ();
        description_textview.get_style_context ().add_class ("description-dialog");
        description_textview.margin = 6;
        description_textview.buffer.text = project.note;
        description_textview.wrap_mode = Gtk.WrapMode.WORD;

        var description_scrolled = new Gtk.ScrolledWindow (null, null);
        description_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        description_scrolled.hexpand = true;
        description_scrolled.height_request = 64;
        description_scrolled.add (description_textview);

        var description_frame = new Gtk.Frame (null);
        description_frame.margin_start = 12;
        description_frame.margin_end = 12;
        description_frame.get_style_context ().add_class ("border-radius-4");
        description_frame.add (description_scrolled);

        var due_label = new Granite.HeaderLabel (_("Deadline:"));

        due_switch = new Gtk.Switch ();
        due_switch.valign = Gtk.Align.CENTER;
        due_switch.get_style_context ().add_class ("active-switch");

        var due_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        due_box.margin_top = 6;
        due_box.margin_start = 12;
        due_box.margin_end = 12;
        due_box.hexpand = true;
        due_box.pack_start (due_label, false, false, 0);
        due_box.pack_end (due_switch, false, false, 0);

        due_datepicker = new Granite.Widgets.DatePicker ();
        due_datepicker.margin_start = 12;
        due_datepicker.margin_end = 12;

        due_revealer = new Gtk.Revealer ();
        due_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        due_revealer.add (due_datepicker);

        if (project.due_date != "") {
            due_switch.active = true;
            due_revealer.reveal_child = true;
            due_datepicker.date = Planner.utils.get_format_date_from_string (project.due_date);
        }

        color_liststore = new Gtk.ListStore (3, typeof (int), typeof (unowned string), typeof (string));
        color_combobox = new Gtk.ComboBox.with_model (color_liststore);
        color_combobox.margin_start = 12;
        color_combobox.margin_end = 12;

        Gtk.TreeIter iter;
        foreach (var color in Planner.utils.get_color_list ()) {
            color_liststore.append (out iter);
            color_liststore.@set (iter,
                0, color,
                1, " " + Planner.utils.get_color_name (color),
                2, "color-%i".printf (color)
            );

            if (project.color == color) {
                color_combobox.set_active_iter (iter);
            }
        }

        var pixbuf_cell = new Gtk.CellRendererPixbuf ();
        color_combobox.pack_start (pixbuf_cell, false);
        color_combobox.add_attribute (pixbuf_cell, "icon-name", 2);

        var text_cell = new Gtk.CellRendererText ();
        color_combobox.pack_start (text_cell, true);
        color_combobox.add_attribute (text_cell, "text", 1);

        var loading_spinner = new Gtk.Spinner ();
        loading_spinner.start ();

        var loading_label = new Gtk.Label (_("Uploading changes…"));

        var loading_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        loading_box.margin_top = 12;
        loading_box.hexpand = true;
        loading_box.pack_start (loading_spinner, false, false, 0);
        loading_box.pack_start (loading_label, false, false, 6);

        var loading_revealer = new Gtk.Revealer ();
        loading_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        loading_revealer.add (loading_box);

        var code = "com.github.alainm23.planner --load-project=%s".printf (project.id.to_string ());
        if (Planner.utils.is_flatpak ()) {
            code = "flatpak run com.github.alainm23.planner --load-project=%s".printf (project.id.to_string ());
        }
        var access_label = new Gtk.Label (code);
        access_label.get_style_context ().add_class ("terminal");
        access_label.selectable = true;

        var access_scrolled = new Gtk.ScrolledWindow (null, null);
        access_scrolled.margin_start = 12;
        access_scrolled.margin_end = 12;
        access_scrolled.valign = Gtk.Align.START;
        access_scrolled.expand = true;
        access_scrolled.add (access_label);

        var convert_header = new Granite.HeaderLabel (_("Options:")) {
            margin_top = 6,
            margin_start = 12,
            margin_end = 12
        };
        var convert_todoist = new Dialogs.Preferences.ItemButton (_("Convert to Todoist"), _("Convert"));

        var convert_grid = new Gtk.Grid ();
        convert_grid.orientation = Gtk.Orientation.VERTICAL;
        convert_grid.add (convert_header);
        convert_grid.add (convert_todoist);
        if (project.is_todoist == 1) {
            convert_grid.visible = false;
            convert_grid.no_show_all = true;
        }

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.valign = Gtk.Align.START;
        grid.expand = true;
        grid.add (new Granite.HeaderLabel (_("Name:")) {
            margin_start = 12,
            margin_end = 12
        });
        grid.add (name_entry);
        //  grid.add (new Granite.HeaderLabel (_("Description:")) {
        //      margin_top = 6,
        //      margin_start = 12,
        //      margin_end = 12
        //  });
        // grid.add (description_frame);
        grid.add (new Granite.HeaderLabel (_("Color:")) {
            margin_top = 6,
            margin_start = 12,
            margin_end = 12
        });
        grid.add (color_combobox);
        grid.add (due_box);
        grid.add (due_revealer);
        grid.add (new Granite.HeaderLabel (_("Direct access:")) {
            margin_top = 6,
            margin_start = 12,
            margin_end = 12
        });
        grid.add (access_scrolled);
        grid.add (convert_grid);
        grid.add (loading_revealer);
        grid.show_all ();

        get_content_area ().add (grid);
        add_button (_("Close"), Gtk.ResponseType.CLOSE);

        var save_button = (Gtk.Button) add_button (_("Save"), Gtk.ResponseType.APPLY);
        save_button.has_default = true;
        save_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        name_entry.changed.connect (() => {
            if (name_entry.text != "") {
                save_button.sensitive = true;
            } else {
                save_button.sensitive = false;
            }
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                destroy ();
            }

            return false;
        });

        name_entry.activate.connect (() => {
            save_and_exit ();
        });

        response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.APPLY) {
                save_and_exit ();
            } else {
                destroy ();
            }
        });
        

        due_switch.notify["active"].connect (() => {
            due_revealer.reveal_child = due_switch.active;
        });

        Planner.todoist.project_updated_started.connect ((id) => {
            if (project.id == id) {
                loading_revealer.reveal_child = true;
            }
        });

        Planner.todoist.project_updated_completed.connect ((id) => {
            if (project.id == id) {
                destroy ();
            }
        });

        Planner.todoist.project_updated_error.connect ((id, error_code, error_message) => {
            if (project.id == id) {
                print ("Error: %s\n".printf (error_message));
            }
        });

        convert_todoist.activated.connect (() => {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Convert Project"),
                _("Are you sure you want to convert <b>%s</b> to Todoist?".printf (Planner.utils.get_dialog_text (project.name))),
                "emblem-synchronized",
            Gtk.ButtonsType.CANCEL);

            var remove_button = new Gtk.Button.with_label (_("Convert"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                Planner.notifications.send_undo_notification (
                    _("Converting project…"),
                    Planner.utils.build_undo_object ("convert_project", "project", project.id.to_string (), "", "")
                );
                Planner.todoist.convert_to_todoist (project);
                destroy ();
            }

            message_dialog.destroy ();
        });
    }

    private void save_and_exit () {
        if (name_entry.text != "") {
            project.name = name_entry.text;
            project.color = get_color_selected ();
            project.note = description_textview.buffer.text;

            if (due_switch.active) {
                project.due_date = due_datepicker.date.to_string ();
            } else {
                project.due_date = "";
            }

            project.save ();
            destroy ();
        }
    }

    public int? get_color_selected () {
        Gtk.TreeIter iter;
        if (!color_combobox.get_active_iter (out iter)) {
            return null;
        }

        Value item;
        color_liststore.get_value (iter, 0, out item);

        return (int) item;
    }
}
