class_name TextEditor
extends CodeEdit


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

var editor_mode = EditorMode.DEFAULT
var vim_mode = VimMode.NORMAL

var line_numbers := true
var line_spacing := 2

var contents_changed := false
var note_open := false
var auto_save := true
var delay_time := 0.5

var font_size := 16
var font


func _input(event: InputEvent) -> void: # {{{
    if event.is_action_pressed("shortcut_save_note", true):
        editable = false
        save()

    if event.is_action_released("shortcut_save_note", true):
        editable = true
# }}}

func save() -> void: # {{{
    contents_changed = false
    save_note.emit(text)
# }}}

func get_settings(): # {{{
    return {
        "line_spacing" : line_spacing,
        "line_numbers" : line_numbers,
        "editor_mode" : editor_mode,
        "delay_time" : delay_time,
        "auto_save" : auto_save,
        "note_open" : note_open,
    }
# }}}

func reload_settings(): # {{{
    gutters_draw_line_numbers = line_numbers
    add_theme_constant_override("line_spacing", line_spacing)
    add_theme_font_size_override("font_size", font_size)
# }}}


func _on_notes_panel_edit_note(contents): # {{{
    text = contents
    note_open = true
    gutters_draw_line_numbers = line_numbers
    contents_changed = false
# }}}

func _on_notes_panel_note_deleted(is_current: bool) -> void: # {{{
    if is_current:
        text = ""
        note_open = false
        contents_changed = false
# }}}


func _on_text_changed() -> void: # {{{
    contents_changed = true
    $Delay.start(delay_time)
# }}}

func _on_delay_timeout() -> void: # {{{
    if auto_save and note_open:
        save()
# }}}

