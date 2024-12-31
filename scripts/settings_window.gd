class_name SettingsWindow
extends Window


const CONFIG_FILE = "user://config.cfg"

enum EditorThemes {
    DEFAULT,
}

var app_theme = EditorThemes.DEFAULT
var config: ConfigFile

## Represents the currently open settings panel
var current_section := "Text Editor"


func _ready() -> void:
    # {{{
    config = ConfigFile.new()
    title = "Settings"
# }}}

func save_settings():
    # {{{
    config.clear()
    var save_nodes = get_tree().get_nodes_in_group("Persist")
    for node in save_nodes:
        if !node.has_method("get_settings"):
            printerr("Persistent node '%s' doesn't have 'get_settings' method, skipping." % node.name)
            continue

        var settings = node.call("get_settings")
        for key in settings.keys():
            config.set_value(node.get_path(), key, settings[key])

    config.save(CONFIG_FILE)
# }}}

func _on_notes_panel_save_note_dates():
    # {{{
    var save_nodes = get_tree().get_nodes_in_group("Persist")
    for node in save_nodes:
        if not node is NoteButton:
            continue

        var settings = node.call("get_settings")
        for key in settings.keys():
            config.set_value(node.get_path(), key, settings[key])

    config.save(CONFIG_FILE)
# }}}

func load_settings():
    # {{{
    var err = config.load(CONFIG_FILE)
    if err != OK:
        printerr("Err: '%s', on config file load." % err)
        return

    for scene_path in config.get_sections():
        var node = get_node_or_null(scene_path)
        if node == null:
            printerr("Invalid node path: '%s', returning." % scene_path)
            return

        for key in config.get_section_keys(scene_path):
            node.set(key, config.get_value(scene_path, key))

        if node.has_method("reload_settings"):
            node.call("reload_settings")
# }}}

func load_default_settings():
    # {{{
    pass
# }}}


func get_settings():
    # {{{
    return {
        "app_theme" : app_theme,
    }
# }}}

func reload_settings():
    # {{{
    var err = config.load(CONFIG_FILE)
    if err != OK:
        printerr("Err: '%s', on config file load." % err)
        return

    for c: SettingsPanel in $TabContainer.get_children():
        if !c.setting_changed.is_connected(_on_settings_panel_setting_changed):
            c.setting_changed.connect(_on_settings_panel_setting_changed)

        var node_name = c.represents_node
        var sect

        for s in config.get_sections():
            if s.get_file() == node_name:
                sect = s

        for k in config.get_section_keys(sect):
            c.set_setting(k, config.get_value(sect, k))
# }}}


func _on_settings_panel_setting_changed(key: String, val):
    # {{{
    var err = config.load(CONFIG_FILE)
    if err != OK:
        printerr("Err: '%s', on config file load." % err)
        return

    var sect
    for s in config.get_sections():
        if s.get_file() == current_section:
            sect = s

    var node = get_node_or_null(sect)
    if node == null:
        printerr("Invalid node path: '%s', returning." % sect)
        return

    config.set_value(sect, key, val)
    node.set(key, val)

    if node.has_method("reload_settings"):
        node.call("reload_settings")

    config.save(CONFIG_FILE)
# }}}

func _on_tab_container_tab_changed(tab: int) -> void:
    # {{{
    var tab_c = $TabContainer.get_tab_control(tab)
    var s = Vector2i(size.x, int(tab_c.custom_minimum_size.y) + 61)
    size = s

    current_section = tab_c.represents_node
# }}}

func _on_exit_pressed() -> void:
    $Exit.release_focus()
    close_requested.emit()
