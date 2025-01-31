extends SettingsPanel


func _ready() -> void: # {{{
    represents_node = "AppTheme"

    for c in $ScrollContainer/GridContainer.get_children():
        if c is ColorPickerButton:
            c.color_changed.connect(_on_color_picker_color_changed.bind(c.name.to_snake_case()))
# }}}

func set_setting(key: String, val) -> void: # {{{
    super(key, val)
# }}}

func _on_theme_preset_item_selected(index: int) -> void: # {{{
    $ScrollContainer/GridContainer/ThemePreset.release_focus()
    setting_changed.emit("theme_preset", index)
# }}}

func _on_color_picker_color_changed(color: Color, color_name: String) -> void: # {{{
    get_node("ScrollContainer/GridContainer/%s" % color_name.to_pascal_case()).release_focus()
    setting_changed.emit(color_name, color)

    $ScrollContainer/GridContainer/ThemePreset.select(0)
    _on_theme_preset_item_selected(0)
# }}}

