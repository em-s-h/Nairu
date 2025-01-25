extends SettingsPanel


@onready var FontPickerScene = preload("res://scenes/font_picker.tscn")


func _ready() -> void: # {{{
    represents_node = "TextEditor"
    setting_changed.connect(_on_settings_changed)
# }}}

func set_setting(key: String, val): # {{{
    super(key, val)
    _on_settings_changed(key, val)
# }}}


func _on_font_pressed() -> void: # {{{
    var font_picker = FontPickerScene.instantiate()
    add_child(font_picker)
    font_picker.show()

    var f_sel = func(font_name):
        font_name = str(font_name)
        $ScrollContainer/GridContainer/Font.text = font_name
        setting_changed.emit("font", font_name)
        
    font_picker.font_selected.connect(f_sel)
# }}}

func _on_font_size_text_submitted(new_text: String) -> void: # {{{
    if !new_text.is_valid_int():
        return 

    $ScrollContainer/GridContainer/FontSize.text = new_text
    $ScrollContainer/GridContainer/FontSize.release_focus()
    setting_changed.emit("font_size", int(new_text))
# }}}


func _on_line_spacing_text_submitted(new_text: String) -> void: # {{{
    if !new_text.is_valid_int():
        return 

    $ScrollContainer/GridContainer/LineSpacing.text = new_text
    $ScrollContainer/GridContainer/LineSpacing.release_focus()
    setting_changed.emit("line_spacing", int(new_text))
# }}}

func _on_line_numbers_toggled(toggled_on: bool) -> void: # {{{
    $ScrollContainer/GridContainer/LineNumbers.release_focus()
    setting_changed.emit("line_numbers", toggled_on)
# }}}


func _on_auto_save_toggled(toggled_on: bool) -> void: # {{{
    $ScrollContainer/GridContainer/AutoSave.release_focus()
    setting_changed.emit("auto_save", toggled_on)
# }}}

func _on_editor_mode_item_selected(index: int) -> void: # {{{
    $ScrollContainer/GridContainer/EditorMode.release_focus()
    setting_changed.emit("editor_mode", index)
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
        "font":
            $ScrollContainer/GridContainer/Font.text = str(def_set)
            setting_changed.emit("font", str(def_set))

        "font_size": _on_font_size_text_submitted(def_set)
        "line_spacing": _on_line_spacing_text_submitted(def_set)
        "editor_mode": _on_editor_mode_item_selected(def_set)

        # "line_numbers": _on_line_numbers_toggled(def_set)
        # "auto_save": _on_auto_save_toggled(def_set)
# }}}

func show_load_default_button(setting_name: String, _show: bool) -> void: # {{{
    var a = 1 if _show else 0
    match setting_name:
        "font": 
            $ScrollContainer/GridContainer/LoadDefaultFont.self_modulate.a = a

        "font_size": 
            $ScrollContainer/GridContainer/LoadDefaultFontSize.self_modulate.a = a

        "line_spacing": 
            $ScrollContainer/GridContainer/LoadDefaultLineSpacing.self_modulate.a = a

        # Toggles
        # "auto_save": 
        #     $ScrollContainer/GridContainer/LoadDefaultAutoSave.self_modulate.a = a
        #
        # "line_numbers":
        #     $ScrollContainer/GridContainer/LoadDefaultLineNumbers.self_modulate.a = a

        "editor_mode":
            $ScrollContainer/GridContainer/LoadDefaultEditorMode.self_modulate.a = a
# }}}
