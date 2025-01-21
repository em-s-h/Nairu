extends SettingsPanel


@export var NotificationDialogScene = preload("res://scenes/notification_dialog.tscn")


func _ready() -> void: # {{{
    represents_node = "NotesPanel"
    setting_changed.connect(_on_settings_changed)
# }}}

func set_setting(key: String, val) -> void: # {{{
    var node_name = key.to_pascal_case()
    var node = get_node_or_null("ScrollContainer/GridContainer/%s" % node_name)

    if node == null:
        prints("Setting '%s' not found, returning." % node_name)
        return

    if node.name == "NoteDirectory" or node.name == "BackupDirectory":
        if "user://" in val:
            val = ProjectSettings.globalize_path(val)

        node.get_node("LineEdit").text = str(val)

    else:
        super(key, val)

    _on_settings_changed(key, val)
# }}}

func create_file_picker(callback_func: Callable, override := false) -> FileDialog: # {{{
    var f = FileDialog.new()
    var on_dir_selected

    if override:
        on_dir_selected = callback_func
    else:
        on_dir_selected = func(dir: String):
            var res = DirAccess.open(dir)
            if res != null:
                callback_func.call(dir)
                return

            var d = NotificationDialogScene.instantiate()
            var msg = "Invalid directory path: '%s',\n" % dir

            d.duration = 5
            d.color = Color.RED
            d.message = msg
            get_tree().root.get_node("Main").add_child(d)

    f.file_mode = FileDialog.FILE_MODE_OPEN_DIR
    f.dir_selected.connect(on_dir_selected)
    f.use_native_dialog = true
    return f
# }}}


func _on_note_directory_pressed() -> void: # {{{
    $ScrollContainer/GridContainer/NoteDirectory.release_focus()

    var on_dir_selected = func(dir: String):
        $ScrollContainer/GridContainer/NoteDirectory/LineEdit.text = dir
        setting_changed.emit("note_directory", dir)
    
    var file_picker = create_file_picker(on_dir_selected)
    add_child(file_picker)
    file_picker.show()
# }}}

func _on_backup_directory_pressed() -> void: # {{{
    $ScrollContainer/GridContainer/BackupDirectory.release_focus()

    var on_dir_selected = func(dir: String):
        $ScrollContainer/GridContainer/BackupDirectory/LineEdit.text = dir
        setting_changed.emit("backup_directory", dir)

    var file_picker = create_file_picker(on_dir_selected)
    add_child(file_picker)
    file_picker.show()
# }}}

func _on_note_directory_line_edit_submitted(new_text: String) -> void: # {{{
    var res = DirAccess.open(new_text)
    if res != null:
        $ScrollContainer/GridContainer/NoteDirectory/LineEdit.text = new_text
        setting_changed.emit("note_directory", new_text)
        return

    var d = NotificationDialogScene.instantiate()
    var msg = "Invalid directory path: '%s',\n" % new_text

    d.duration = 5
    d.color = Color.RED
    d.message = msg
    get_tree().root.get_node("Main").add_child(d)
# }}}

func _on_backup_directory_line_edit_submitted(new_text: String) -> void: # {{{
    var res = DirAccess.open(new_text)
    if res != null:
        $ScrollContainer/GridContainer/BackupDirectory/LineEdit.text = new_text
        setting_changed.emit("backup_directory", new_text)
        return

    var d = NotificationDialogScene.instantiate()
    var msg = "Invalid directory path: '%s',\n" % new_text

    d.duration = 5
    d.color = Color.RED
    d.message = msg
    get_tree().root.get_node("Main").add_child(d)
# }}}


func _on_backup_option_item_selected(index: int) -> void: # {{{
    $ScrollContainer/GridContainer/BackupOption.release_focus()
    setting_changed.emit("backup_option", index)
# }}}

func _on_date_format_item_selected(index: int) -> void: # {{{
    $ScrollContainer/GridContainer/DateFormat.release_focus()
    setting_changed.emit("date_format", index)
# }}}

func _on_keep_open_toggled(toggled_on: bool) -> void: # {{{
    $ScrollContainer/GridContainer/KeepOpen.release_focus()
    setting_changed.emit("keep_open", toggled_on)
# }}}


func _on_settings_changed(key: String, val) -> void: # {{{
    var def_set = settings.get_default_setting(key, represents_node)
    if typeof(def_set) == typeof(ERR_DOES_NOT_EXIST) and def_set == ERR_DOES_NOT_EXIST:
        printerr("Unable to load default config, returning.")
        printerr("setting_name: '%s', of node: '%s'" % [key, represents_node])

    if "user://" in str(def_set):
        def_set = ProjectSettings.globalize_path(def_set)
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
        "backup_option": _on_backup_option_item_selected(def_set)
        "date_format": _on_date_format_item_selected(def_set)
        "keep_open": _on_keep_open_toggled(def_set)

        "backup_directory":
            if "user://" in def_set:
                def_set = ProjectSettings.globalize_path(def_set)
            $ScrollContainer/GridContainer/BackupDirectory/LineEdit.text = def_set
            setting_changed.emit("backup_directory", def_set)

        "note_directory": 
            if "user://" in def_set:
                def_set = ProjectSettings.globalize_path(def_set)
            $ScrollContainer/GridContainer/NoteDirectory/LineEdit.text = def_set
            setting_changed.emit("note_directory", def_set)
# }}}

func show_load_default_button(setting_name: String, _show: bool) -> void: # {{{
    var a = 1 if _show else 0
    match setting_name:
        "backup_option": 
            $ScrollContainer/GridContainer/LoadDefaultBackupOption.self_modulate.a = a

        "date_format": 
            $ScrollContainer/GridContainer/LoadDefaultDateFormat.self_modulate.a = a

        # Toggle
        # "keep_open": 
        #     $ScrollContainer/GridContainer/LoadDefaultKeepOpen.self_modulate.a = a

        "backup_directory":
            $ScrollContainer/GridContainer/LoadDefaultBackupDirectory.self_modulate.a = a

        "note_directory":
            $ScrollContainer/GridContainer/LoadDefaultNoteDirectory.self_modulate.a = a
# }}}
