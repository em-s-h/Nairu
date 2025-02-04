extends SettingsPanel


@onready var NotificationDialogScene = preload("res://scenes/notification_dialog.tscn")


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

    var notif: NotificationDialog = NotificationDialogScene.instantiate()
    notif.type = NotificationDialog.NotificationType.NORMAL
    notif.message = "Loading theme"
    notif.duration = 1
    get_tree().root.get_node("Main/Settings/SettingsWindow").add_child(notif)

    await get_tree().create_timer(0.5).timeout
    setting_changed.emit("theme_preset", index)

    await get_tree().create_timer(0.6).timeout
    get_tree().root.get_node("Main/Settings").reload_settings_window()
# }}}

func _on_color_picker_color_changed(color: Color, color_name: String) -> void: # {{{
    var col_pick = get_node("ScrollContainer/GridContainer/%s" % color_name.to_pascal_case())
    col_pick.release_focus()

    get_tree().root.get_node("Main/Settings/AppTheme").theme_preset = AppTheme.ThemePresets.CUSTOM
    $ScrollContainer/GridContainer/ThemePreset.select(0)
    
    var notif: NotificationDialog = NotificationDialogScene.instantiate()
    notif.type = NotificationDialog.NotificationType.NORMAL
    notif.message = "Loading theme"
    notif.duration = 1
    get_tree().root.get_node("Main/Settings/SettingsWindow").add_child(notif)

    var c = col_pick.get_child(0, true)
    c.queue_free()

    await get_tree().create_timer(0.5).timeout
    setting_changed.emit(color_name, color)
# }}}

