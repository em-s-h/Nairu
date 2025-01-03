extends SettingsPanel


func _ready() -> void:
    represents_node = "Settings"


func _on_app_theme_item_selected(index: int) -> void:
    # {{{
    $ScrollContainer/GridContainer/AppTheme.release_focus()
    setting_changed.emit("app_theme", index)
# }}}

