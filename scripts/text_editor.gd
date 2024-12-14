class_name TextEditor
extends TextEdit


enum EditorMode {
    DEFAULT,
    VIM,
}

enum VimMode {
    NORMAL,
    INSERT,
    COMMAND,
}

signal save_note(contents)

var line_separators := false
var line_numbers := false

var editor_mode = EditorMode.DEFAULT
var vim_mode = VimMode.NORMAL

var note_open := false
var auto_save := false


# func _ready() -> void:
    # {{{
# }}}

func _input(event: InputEvent) -> void:
    # {{{
    var ctrl = InputEventKey.new()
    ctrl.keycode = KEY_CTRL

    if event.is_match(ctrl, false) and editor_mode != EditorMode.VIM:
        editable = event.is_released()

    if event.is_action("shortcut_save_note") and event.is_released():
        save()
# }}}

## Emit `save_note` signal
##
## Shorter way of doing `save_note.emit(text)`
func save():
    # {{{
    save_note.emit(text)
# }}}

func get_settings():
    # {{{
    return {
        "line_separators" : line_separators,
        "line_numbers" : line_numbers,
        "editor_mode" : editor_mode,
        "auto_save" : auto_save,
        "note_open" : note_open,
    }
# }}}

func reload_settings():
    # {{{
    pass
# }}}


func _on_text_changed() -> void:
    # {{{
    if !auto_save:
        return

    save_note.emit(text)
# }}}

func _on_notes_panel_edit_note(contents):
    # {{{
    text = contents
    note_open = true
# }}}

func _on_notes_panel_note_deleted():
    # {{{
    text = ""
    note_open = false
# }}}
