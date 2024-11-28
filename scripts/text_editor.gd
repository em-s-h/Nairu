class_name TextEditor
extends TextEdit


const TEXT_EDIT_DEFAULT_SIZE = Vector2(720, 800)


enum EditorMode {
    DEFAULT,
    VIM,
}


enum VimMode {
    NORMAL,
    INSTERT,
    COMMAND,
}


signal save_note(_note)


var editor_mode
var vim_mode

var notes_panel
var note

var auto_save_timer
var auto_save


func _input(event: InputEvent) -> void:
    if event.is_action("shortcut_save_note"):
        save_note.emit(note)


func edit_note(_note):
    pass
