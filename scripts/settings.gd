class_name Settings
extends Node


const CONFIG_PATH = "user://config.cfg"

var SettingsWindowScene = preload("res://scenes/settings_window.tscn")
var settings_window: SettingsWindow

var config: ConfigFile


func _ready() -> void: 
    config = ConfigFile.new()


func open_settings(): 
    settings_window = SettingsWindowScene.instantiate()
    add_child(settings_window)

    settings_window.close_requested.connect(_on_settings_window_close_requested)

    var tab_cont = settings_window.get_node("Panel/TabContainer")
    for c in tab_cont.get_children():
        if c is SettingsPanel:
            c.setting_changed.connect(_on_settings_panel_setting_changed)
            c.settings = self

    var err = config.load(CONFIG_PATH)
    if err != OK:
        var d = ErrorDialog.new()
        var msg = "Unable to open settings window:\n"
        msg += "configuration file could not be loaded.\n"
        msg += "Error: '%s'" % ErrorDialog.expand_error_code(err)

        d.dialog_text = msg
        add_child(d)

        settings_window.queue_free()
        return

    settings_window.reload_settings(config)
    settings_window.name = "SettingsWindow"
    settings_window.show()


func reload_settings_window() -> void: 
    settings_window.queue_free()
    await get_tree().create_timer(0.1).timeout
    open_settings()


func save_settings(): 
    config.clear()
    var save_nodes = get_tree().get_nodes_in_group("Persist")
    for node in save_nodes:
        if !node.has_method("get_settings"):
            prints("Persistent node '%s' doesn't have 'get_settings' method, skipping." % node.name)
            continue

        var settings = node.call("get_settings")
        for key in settings.keys():
            config.set_value(node.get_path(), key, settings[key])

    config.save(CONFIG_PATH)


func load_settings(): 
    var err = config.load(CONFIG_PATH)
    if err != OK:
        var d = ErrorDialog.new()
        var msg = "Unable to load configuration file.\n"
        msg += "Error: '%s'" % ErrorDialog.expand_error_code(err)

        d.dialog_text = msg
        d.ok_button_text = "Continue with default settings"

        d.add_cancel_button("Close application")
        d.canceled.connect(func(): get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST))

        add_child(d)
        return

    for scene_path in config.get_sections():
        var node = get_node_or_null(scene_path)
        if node == null:
            prints("Invalid node path: '%s', skipping." % scene_path)
            continue

        for key in config.get_section_keys(scene_path):
            node.set(key, config.get_value(scene_path, key))

        if node.has_method("reload_settings"):
            node.call("reload_settings")



func _on_notes_panel_save_note_dates(): 
    var save_nodes = get_tree().get_nodes_in_group("Persist")
    for node in save_nodes:
        if not node is NoteButton:
            continue

        var settings = node.call("get_settings")
        for key in settings.keys():
            config.set_value(node.get_path(), key, settings[key])

    config.save(CONFIG_PATH)


func get_default_setting(setting_name: String, from_node: String): 
    var p_nodes = get_tree().get_nodes_in_group("Persist")
    for node in p_nodes:
        if node is Settings:
            continue

        if !node.has_method("get_default_setting"):
            prints("Persistent node '%s' doesn't have 'get_default_setting' method, skipping." % node.name)
            continue

        if node.name == from_node:
            return node.call("get_default_setting", setting_name)

    return ERR_INVALID_PARAMETER


func _on_settings_panel_setting_changed(key: String, val): 
    var err = config.load(CONFIG_PATH)
    if err != OK:
        var d = ErrorDialog.new()
        var msg = "Unable to load configuration file, settings not saved.\n"
        msg += "Error: '%s'" % ErrorDialog.expand_error_code(err)

        d.dialog_text = msg
        $SettingsWindow.add_child(d)
        return

    var sect
    for s in config.get_sections():
        if s.get_file() == settings_window.current_section:
            sect = s

    var node = get_node_or_null(sect)
    if node == null:
        printerr("Invalid node path: '%s', returning." % sect)
        return

    prints("%s changed" % key)
    config.set_value(sect, key, val)
    node.set(key, val)

    if node.has_method("reload_settings"):
        node.call("reload_settings")

    config.save(CONFIG_PATH)


func _on_settings_window_close_requested() -> void:
    settings_window.queue_free()
