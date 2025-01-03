class_name Settings
extends Node


const CONFIG_PATH = "user://config.cfg"

enum EditorThemes {
    DEFAULT,
}

var SettingsWindowScene = preload("res://scenes/settings_window.tscn")
var settings_window: SettingsWindow

var app_theme = EditorThemes.DEFAULT
var config: ConfigFile


func _ready() -> void:
    # {{{
    config = ConfigFile.new()
# }}}

func open_settings():
    # {{{
    settings_window = _create_settings_scene()
    add_child(settings_window)

    var err = config.load(CONFIG_PATH)
    if err != OK:
        printerr("Err: '%s', on config file load." % err)
        return

    settings_window.reload_settings(config)
    settings_window.show()
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

    config.save(CONFIG_PATH)
# }}}

func load_settings():
    # {{{
    var err = config.load(CONFIG_PATH)
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

func _on_notes_panel_save_note_dates():
    # {{{
    var save_nodes = get_tree().get_nodes_in_group("Persist")
    for node in save_nodes:
        if not node is NoteButton:
            continue

        var settings = node.call("get_settings")
        for key in settings.keys():
            config.set_value(node.get_path(), key, settings[key])

    config.save(CONFIG_PATH)
# }}}


func get_settings():
    # {{{
    return {
        "app_theme" : app_theme,
    }
# }}}

func reload_settings():
    # {{{
    pass
# }}}


func _on_settings_panel_setting_changed(key: String, val):
    # {{{
    var err = config.load(CONFIG_PATH)
    if err != OK:
        printerr("Err: '%s', on config file load." % err)
        return

    var sect
    for s in config.get_sections():
        if s.get_file() == settings_window.current_section:
            sect = s

    var node = get_node_or_null(sect)
    if node == null:
        printerr("Invalid node path: '%s', returning." % sect)
        return

    config.set_value(sect, key, val)
    node.set(key, val)

    if node.has_method("reload_settings"):
        node.call("reload_settings")

    config.save(CONFIG_PATH)
# }}}

func _on_settings_window_close_requested() -> void:
    settings_window.queue_free()

func _create_settings_scene():
    # {{{
    var i: SettingsWindow = SettingsWindowScene.instantiate()

    i.close_requested.connect(_on_settings_window_close_requested)
    for c in i.get_children():
        if c is SettingsPanel:
            c.setting_changed.connect(_on_settings_panel_setting_changed)

    return i
# }}}
