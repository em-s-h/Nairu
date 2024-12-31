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

func _on_note_directory_pressed() -> void:
    # {{{
    $ScrollContainer/GridContainer/NoteDirectory.release_focus()
    var file_picker = FileDialog.new()

    var on_dir_selected = func(dir: String):
        var res = DirAccess.open(dir)
        if res == null:
            printerr("Invalid directory path: '%s', returning.", % dir)
            printerr("Err: '%s'" % DirAccess.get_open_error())
            return

        $ScrollContainer/GridContainer/NoteDirectory.text = dir
        setting_changed.emit("note_directory", dir)

    file_picker.file_mode = FileDialog.FILE_MODE_OPEN_DIR
    file_picker.dir_selected.connect(on_dir_selected)
    file_picker.use_native_dialog = true
    
    add_child(file_picker)
    file_picker.show()
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

