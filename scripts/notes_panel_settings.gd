extends SettingsPanel


func _ready() -> void:
    represents_node = "NotesPanel"


func set_setting(key: String, val) -> void:
    # {{{
    var node_name = key.to_pascal_case()
    var node = get_node_or_null("ScrollContainer/GridContainer/%s" % node_name)

    if node == null:
        printerr("Invalid node: '%s', returning." % node_name)
        return

    if node is Button and node.get_child_count() == 1:
        node.text = ""
        if "user://" in val:
            val = ProjectSettings.globalize_path(val)

        node.get_child(0).text = str(val)

    else:
        super(key, val)
# }}}

func create_file_picker(callback_func: Callable, override := false) -> FileDialog:
    # {{{
    var f = FileDialog.new()
    var on_dir_selected

    if override:
        on_dir_selected = callback_func
    else:
        on_dir_selected = func(dir: String):
            var res = DirAccess.open(dir)
            if res == null:
                printerr("Invalid directory path: '%s', returning.", % dir)
                printerr("Err: '%s'" % DirAccess.get_open_error())
                return
            callback_func.call(dir)

    f.file_mode = FileDialog.FILE_MODE_OPEN_DIR
    f.dir_selected.connect(on_dir_selected)
    f.use_native_dialog = true
    return f
# }}}

func _on_note_directory_pressed() -> void:
    # {{{
    $ScrollContainer/GridContainer/NoteDirectory.release_focus()

    var on_dir_selected = func(dir: String):
        $ScrollContainer/GridContainer/NoteDirectory.text = dir
        setting_changed.emit("note_directory", dir)
    
    var file_picker = create_file_picker(on_dir_selected)
    add_child(file_picker)
    file_picker.show()
# }}}

func _on_backup_directory_pressed() -> void:
    # {{{
    $ScrollContainer/GridContainer/BackupDirectory.release_focus()

    var on_dir_selected = func(dir: String):
        $ScrollContainer/GridContainer/BackupDirectory.text = dir
        setting_changed.emit("backup_directory", dir)

    var file_picker = create_file_picker(on_dir_selected)
    add_child(file_picker)
    file_picker.show()
# }}}

func _on_backup_option_item_selected(index: int) -> void:
    # {{{
    $ScrollContainer/GridContainer/BackupOption.release_focus()
    setting_changed.emit("backup_option", index)
# }}}

func _on_date_format_item_selected(index: int) -> void:
    # {{{
    $ScrollContainer/GridContainer/DateFormat.release_focus()
    setting_changed.emit("date_format", index)
# }}}

func _on_keep_open_toggled(toggled_on: bool) -> void:
    # {{{
    $ScrollContainer/GridContainer/KeepOpen.release_focus()
    setting_changed.emit("keep_open", toggled_on)
# }}}

