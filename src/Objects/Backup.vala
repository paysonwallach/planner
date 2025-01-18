/*
* Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
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

public class Objects.Backup : Object {
    public string version { get; set; default = ""; }
    public string date { get; set; default = new GLib.DateTime.now_local ().to_string (); }

    public int default_inbox { get; set; default = 0; }
    public string local_inbox_project_id { get; set; default = ""; }
    public string todoist_access_token { get; set; default = ""; }
    public string todoist_sync_token { get; set; default = ""; }
    public string todoist_user_name { get; set; default = ""; }
    public string todoist_user_email { get; set; default = ""; }
    public string todoist_user_image_id { get; set; default = ""; }
    public string todoist_user_avatar { get; set; default = ""; }
    public bool todoist_user_is_premium { get; set; default = false; }

    public Gee.ArrayList<Objects.Project> projects { get; set; default = new Gee.ArrayList<Objects.Project> (); }
    public Gee.ArrayList<Objects.Section> sections { get; set; default = new Gee.ArrayList<Objects.Section> (); }
    public Gee.ArrayList<Objects.Item> items { get; set; default = new Gee.ArrayList<Objects.Item> (); }
    public Gee.ArrayList<Objects.Label> labels { get; set; default = new Gee.ArrayList<Objects.Label> (); }
    public Gee.ArrayList<Objects.Source> sources { get; set; default = new Gee.ArrayList<Objects.Source> (); }

    public string path { get; set; }
    public string error { get; set; default = ""; }

    GLib.DateTime _datetime;
    public GLib.DateTime datetime {
        get {
            _datetime = new GLib.DateTime.from_iso8601 (date, new GLib.TimeZone.local ());
            return _datetime;
        }
    }

    private string _title;
    public string title {
        get {
            _title = datetime.format ("%c");
            return _title;
        }
    }

    private bool _todoist_backend;
    public bool todoist_backend {
        get {
            _todoist_backend = todoist_access_token.strip () != "";
            return _todoist_backend;
        }
    }

    public signal void deleted ();

    public Backup.from_file (File file) {
        var parser = new Json.Parser ();

        try {
            parser.load_from_file (file.get_path ());
            path = file.get_path ();

            var node = parser.get_root ().get_object ();
            
            version = node.get_string_member ("version");
            date = node.get_string_member ("date");
    
            // Set Settings
            var settings = node.get_object_member ("settings");
            local_inbox_project_id = settings.get_string_member ("local-inbox-project-id");

            if (settings.has_member ("todoist-access-token")) {
                todoist_access_token = settings.get_string_member ("todoist-access-token");
            }

            if (settings.has_member ("todoist-sync-token")) {
                todoist_sync_token = settings.get_string_member ("todoist-sync-token");
            }

            if (settings.has_member ("todoist-user-name")) {
                todoist_user_name = settings.get_string_member ("todoist-user-name");
            }

            if (settings.has_member ("todoist-user-email")) {
                todoist_user_email = settings.get_string_member ("todoist-user-name");
            }

            if (settings.has_member ("todoist-user-image-id")) {
                todoist_user_image_id = settings.get_string_member ("todoist-user-image-id");
            }

            if (settings.has_member ("todoist-user-avatar")) {
                todoist_user_avatar = settings.get_string_member ("todoist-user-avatar");
            }

            if (settings.has_member ("todoist-user-is-premium")) {
                todoist_user_is_premium = settings.get_boolean_member ("todoist-user-is-premium");
            }

            // Sources
            sources.clear ();
            unowned Json.Array _sources = node.get_array_member ("sources");
            foreach (unowned Json.Node item in _sources.get_elements ()) {
                sources.add (new Objects.Source.from_import_json (item));
            }

            if (version == "1.0" && todoist_access_token.strip () != "") {
                var todoist_source = new Objects.Source ();
                todoist_source.id = SourceType.TODOIST.to_string ();
                todoist_source.source_type = SourceType.TODOIST;
                todoist_source.display_name = todoist_user_email;

                Objects.SourceTodoistData todoist_data = new Objects.SourceTodoistData ();
                todoist_data.sync_token = todoist_sync_token;
                todoist_data.access_token = todoist_access_token;
                todoist_data.user_email = todoist_user_email;
                todoist_data.user_name = todoist_user_email;
                todoist_data.user_avatar = todoist_user_avatar;
                todoist_data.user_image_id = todoist_user_image_id;
                todoist_data.user_is_premium = todoist_user_is_premium;
                todoist_source.data = todoist_data;

                sources.add (todoist_source);
            }

            // Labels
            labels.clear ();
            unowned Json.Array _labels = node.get_array_member ("labels");
            foreach (unowned Json.Node item in _labels.get_elements ()) {
                labels.add (new Objects.Label.from_import_json (item));
            }
                
            // Projects
            projects.clear ();
            unowned Json.Array _projects = node.get_array_member ("projects");
            foreach (unowned Json.Node item in _projects.get_elements ()) {
                var _project = new Objects.Project.from_import_json (item);

                if (version == "1.0") {
                    if (_project.source_id != SourceType.CALDAV.to_string ()) {
                        projects.add (_project);
                    }
                } else {
                    projects.add (_project);
                }
            }
                
            // Sections
            sections.clear ();
            unowned Json.Array _sections = node.get_array_member ("sections");
            foreach (unowned Json.Node item in _sections.get_elements ()) {
                sections.add (new Objects.Section.from_import_json (item));
            }
                
            // Items
            items.clear ();
            unowned Json.Array _items = node.get_array_member ("items");
            foreach (unowned Json.Node item in _items.get_elements ()) {
                items.add (new Objects.Item.from_import_json (item, labels));
            }
        } catch (Error e) {
            error = e.message;
        }
    }

    public bool valid () {
        if (error != "") {
            return false;
        }

        if (version == null || version == "") {
            return false;
        }

        if (date == null || date == "") {
            return false;
        }

        if (projects.is_empty) {
            return false;
        }

        return true;
    }
}
