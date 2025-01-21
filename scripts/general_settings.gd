extends SettingsPanel


func _ready() -> void:
    represents_node = "Settings"
    setting_changed.connect(_on_settings_changed)


func set_setting(key: String, val): # {{{
    super(key, val)
    _on_settings_changed(key, val)
# }}}

func _on_app_theme_item_selected(index: int) -> void: # {{{
    $ScrollContainer/GridContainer/AppTheme.release_focus()
    setting_changed.emit("app_theme", index)
# }}}


func _on_settings_changed(key: String, val) -> void: # {{{
    var def_set = settings.get_default_setting(key, represents_node)
    if typeof(def_set) == typeof(ERR_DOES_NOT_EXIST) && def_set == ERR_DOES_NOT_EXIST:
        printerr("Unable to load default config, returning.")
        printerr("setting_name: '%s', of node: '%s'" % [key, represents_node])

    show_load_default_button(key, val != def_set)
# }}}

func _on_load_default_setting_pressed(setting_name: String) -> void: # {{{
    var def_set = settings.get_default_setting(setting_name, represents_node)
    if typeof(def_set) == typeof(ERR_DOES_NOT_EXIST) && def_set == ERR_DOES_NOT_EXIST:
        printerr("Unable to load default config, returning.")
        printerr("setting_name: '%s', of node: '%s'" % [setting_name, represents_node])

    show_load_default_button(setting_name, false)
    set_setting(setting_name, def_set)

    match setting_name:
        "app_theme": _on_app_theme_item_selected(def_set)
# }}}

func show_load_default_button(setting_name: String, _show: bool) -> void: # {{{
    var a = 1 if _show else 0
    match setting_name:
        "font_size": 
            $ScrollContainer/GridContainer/LoadDefaultAppTheme.self_modulate.a = a
# }}}
