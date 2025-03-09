class_name TextEditor
extends CodeEdit


const DEFAULT_LINE_NUMBERS  := true
const DEFAULT_LINE_SPACING  := 2
const DEFAULT_AUTO_SAVE     := false
const DEFAULT_DELAY_TIME    := 0.5
const DEFAULT_FONT_SIZE     := 16
const DEFAULT_FONT          := "monospace"

signal save_note(contents: String)

var line_numbers := DEFAULT_LINE_NUMBERS
var line_spacing := DEFAULT_LINE_SPACING

var auto_save := DEFAULT_AUTO_SAVE
var delay_time := DEFAULT_DELAY_TIME

var font_size := DEFAULT_FONT_SIZE
var font := DEFAULT_FONT

var contents_changed := false
var note_open := false


func _input(event: InputEvent) -> void: 
    if event.is_action_pressed("shortcut_save_note", false, true):
        editable = false
        save()

    if event.is_action_released("shortcut_save_note", true):
        editable = note_open


func save() -> void: 
    contents_changed = false
    save_note.emit(text)

func get_settings(): 
    return {
        "line_spacing" : line_spacing,
        "line_numbers" : line_numbers,
        "delay_time" : delay_time,
        "auto_save" : auto_save,
        "note_open" : note_open,
        "font": font,
    }

func reload_settings(): 
    gutters_draw_line_numbers = line_numbers
    add_theme_constant_override("line_spacing", line_spacing)
    add_theme_font_size_override("font_size", font_size)

    var f: SystemFont = load(AppTheme.FONT_PATH)
    var f_names = PackedStringArray([str(font)])
    f.font_names = f_names

    add_theme_font_override("font", f)
    text += ""

    editable = note_open
    grab_focus()

func get_default_setting(setting_name: String): 
    match setting_name: 
        "auto_save"     : return DEFAULT_AUTO_SAVE
        "delay_time"    : return DEFAULT_DELAY_TIME
        "line_numbers"  : return DEFAULT_LINE_NUMBERS
        "line_spacing"  : return DEFAULT_LINE_SPACING
        "font_size"     : return DEFAULT_FONT_SIZE
        "font"          : return DEFAULT_FONT
        _               : return ERR_DOES_NOT_EXIST


func _on_notes_panel_edit_note(contents): 
    text = contents
    note_open = true
    gutters_draw_line_numbers = line_numbers
    contents_changed = false

func _on_notes_panel_note_deleted(is_current: bool) -> void: 
    if is_current:
        text = ""
        note_open = false
        contents_changed = false


func _on_text_changed() -> void: 
    contents_changed = true
    $Delay.start(delay_time)

func _on_delay_timeout() -> void: 
    if auto_save and note_open:
        save()


