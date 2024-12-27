extends SettingsPanel


func _ready() -> void:
    represents_node = "TextEditor"


func _on_font_size_text_submitted(new_text: String) -> void:
    # {{{
    if !new_text.is_valid_int():
        return 

    $ScrollContainer/GridContainer/FontSize.text = new_text
    $ScrollContainer/GridContainer/FontSize.release_focus()
    setting_changed.emit("font_size", int(new_text))
# }}}

func _on_line_spacing_text_submitted(new_text: String) -> void:
    # {{{
    if !new_text.is_valid_int():
        return 

    $ScrollContainer/GridContainer/LineSpacing.text = new_text
    $ScrollContainer/GridContainer/LineSpacing.release_focus()
    setting_changed.emit("line_spacing", int(new_text))
# }}}

func _on_auto_save_toggled(toggled_on: bool) -> void:
    # {{{
    $ScrollContainer/GridContainer/AutoSave.release_focus()
    setting_changed.emit("auto_save", toggled_on)
# }}}

func _on_line_numbers_toggled(toggled_on: bool) -> void:
    # {{{
    $ScrollContainer/GridContainer/LineNumbers.release_focus()
    setting_changed.emit("line_numbers", toggled_on)
# }}}

func _on_editor_mode_item_selected(index: int) -> void:
    # {{{
    $ScrollContainer/GridContainer/EditorMode.release_focus()
    setting_changed.emit("editor_mode", index)
# }}}
