class_name SettingsPanel
extends Node


const CONFIG_FILE = "user://config.cfg"

enum EditorThemes {
    DEFAULT,
}

var config: ConfigFile
var theme = EditorThemes.DEFAULT
var font_size
var font


func _ready() -> void:
    config = ConfigFile.new()


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

func load_settings():
    # {{{
    if !FileAccess.file_exists(CONFIG_FILE):
        printerr("Config file doesn't exist.")
        return

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
    pass


func get_settings():
    # {{{
    return {
        "theme" : theme,
        "font_size" : font_size,
        "font" : font,
    }
# }}}

func _on_config_loaded():
    # {{{
    # Reset theme and stuff
    pass
# }}}
