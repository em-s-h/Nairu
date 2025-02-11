class_name TextEditor
extends CodeEdit


const DEFAULT_EDITOR_MODE   := EditorMode.DEFAULT
const DEFAULT_LINE_NUMBERS  := true
const DEFAULT_LINE_SPACING  := 2
const DEFAULT_AUTO_SAVE     := false
const DEFAULT_DELAY_TIME    := 0.5
const DEFAULT_FONT_SIZE     := 16
const DEFAULT_FONT          := "monospace"

enum EditorMode {
    DEFAULT,
    VIM,
}

enum VimMode {
    NORMAL,
    VISUAL,
    INSERT,
    COMMAND,
}

enum VimAction {
    NONE,
    APPEND,
    DELETE,
    DELETE_AND_INSERT,
    YANK,
}

enum VimMotion {
    WORD_END_FORWARD,
    WORD_FORWARD,
    WORD_BACK,
    START_OF_LINE,
    END_OF_LINE,
}

signal save_note(contents: String)
signal edit_note(note_name: String)

var line_numbers := DEFAULT_LINE_NUMBERS
var line_spacing := DEFAULT_LINE_SPACING

var auto_save := DEFAULT_AUTO_SAVE
var delay_time := DEFAULT_DELAY_TIME

var font_size := DEFAULT_FONT_SIZE
var font := DEFAULT_FONT

var editor_mode := DEFAULT_EDITOR_MODE
var command_line: CommandLine
var vim_mode := VimMode.NORMAL

var pending_action := VimAction.NONE
var selection_start := Vector2i.ZERO
var select_lines := false

var contents_changed := false
var note_open := false

var line_length: int:
    set(_val): printerr("Cannot set line lenght")
    get: return len(get_line(get_caret_line()))


func _input(_event: InputEvent) -> void: 
    if not _event is InputEventKey:
        return

    var event: InputEventKey = _event

    if event.is_action_pressed("shortcut_save_note", true):
        editable = false
        save()

    if event.is_action_released("shortcut_save_note", true):
        editable = editor_mode != EditorMode.VIM

    if editor_mode != EditorMode.VIM:
        return

    var caret_pos := Vector2i(get_caret_column(), get_caret_line())

    if event.is_action_pressed("vim_yank"):
        if event.ctrl_pressed or vim_mode == VimMode.INSERT or vim_mode == VimMode.COMMAND:
            return
        var reset_pos := false

        if event.shift_pressed and vim_mode == VimMode.NORMAL:
            select(caret_pos.y, caret_pos.x, caret_pos.y, line_length)
            reset_pos = true
        elif pending_action != VimAction.YANK and vim_mode == VimMode.NORMAL:
            pending_action = VimAction.YANK
            return
        elif pending_action == VimAction.YANK and vim_mode == VimMode.NORMAL:
            select(caret_pos.y, 0, caret_pos.y, line_length)
            reset_pos = true

        copy()
        if reset_pos == true:
            set_caret_column(caret_pos.x)
            set_caret_line(caret_pos.y)
        enable_normal_mode()

    if event.is_action_pressed("vim_normal_mode", false, true):
        enable_normal_mode()

    var can_move = vim_mode == VimMode.NORMAL or vim_mode == VimMode.VISUAL
    if event.is_action_pressed("vim_up", true, true) and can_move:
        move_cursor(Vector2i.UP)
    elif event.is_action_pressed("vim_down", true, true) and can_move:
        move_cursor(Vector2i.DOWN)

    elif event.is_action_pressed("vim_left", true, true) and can_move:
        move_cursor(Vector2i.LEFT)
    elif event.is_action_pressed("vim_right", true, true) and can_move:
        move_cursor(Vector2i.RIGHT)

    if vim_mode != VimMode.NORMAL or event.ctrl_pressed:
        return

    if event.is_action_released("vim_insert_mode"):
        if event.shift_pressed:
            set_caret_column(0)
        enable_insert_mode()

    elif event.is_action_released("vim_append"):
        var c = caret_pos.x + 1
        if event.shift_pressed:
            c = line_length

        set_caret_column(c)
        enable_insert_mode()

    elif event.is_action_released("vim_delete_and_insert"):
        if event.shift_pressed:
            select(caret_pos.y, caret_pos.x, caret_pos.y, line_length)
        elif pending_action != VimAction.DELETE_AND_INSERT:
            pending_action = VimAction.DELETE_AND_INSERT
            return
        elif pending_action == VimAction.DELETE_AND_INSERT:
            select(caret_pos.y, 0, caret_pos.y, line_length)

        cut()
        enable_insert_mode()

    elif event.is_action_pressed("vim_delete"):
        if event.shift_pressed:
            select(caret_pos.y, caret_pos.x, caret_pos.y, line_length)
        elif pending_action != VimAction.DELETE:
            pending_action = VimAction.DELETE
            return
        elif pending_action == VimAction.DELETE:
            select(caret_pos.y, 0, caret_pos.y, line_length)

        cut()
        enable_normal_mode()

    elif event.is_action_pressed("vim_delete_character", true):
        if event.shift_pressed:
            select(caret_pos.y, caret_pos.x, caret_pos.y, caret_pos.x - 1)
        else:
            select(caret_pos.y, caret_pos.x, caret_pos.y, caret_pos.x + 1)

        cut()
        enable_normal_mode()

    elif event.is_action_pressed("vim_undo", true, true) and has_undo():
        undo()
    elif event.is_action_pressed("vim_redo", true, true) and has_redo():
        redo()

    elif event.is_action_pressed("vim_motion_e", true):
        process_motion(VimMotion.WORD_END_FORWARD)
    elif event.is_action_pressed("vim_motion_b", true):
        process_motion(VimMotion.WORD_BACK)
    elif event.is_action_pressed("vim_motion_b", true):
        process_motion(VimMotion.WORD_FORWARD)
    elif event.is_action_pressed("vim_motion_start_of_line"):
        set_caret_column(0)
    elif event.is_action_pressed("vim_motion_end_of_line"):
        set_caret_column(line_length)

    elif event.is_action_pressed("vim_visual_mode"):
        if vim_mode == VimMode.VISUAL:
            enable_normal_mode.call()
            return

        selection_start = caret_pos
        select_lines = event.shift_pressed
        if select_lines:
            select(caret_pos.y, 0, caret_pos.y, line_length)

        command_line.text = "-- VISUAL --"
        vim_mode = VimMode.VISUAL

    elif event.is_action_pressed("vim_command_mode"):
        caret_draw_when_editable_disabled = false
        vim_mode = VimMode.COMMAND

        command_line.editable = true
        command_line.grab_focus()
        command_line.caret_column = len(command_line.text)


func _cut(caret_index: int) -> void: 
    copy(caret_index)
    delete_selection(caret_index)



func process_motion(motion: VimMotion) -> void: 
    var next_word_start := false
    var curr_word_start := false

    match motion:
        VimMotion.WORD_END_FORWARD: curr_word_start = false
        VimMotion.WORD_FORWARD:     next_word_start = true
        VimMotion.WORD_BACK:        curr_word_start = true
        
    var amnt = 1 if !curr_word_start or next_word_start else -1

    var pos = Vector2i(get_caret_column(), get_caret_line())
    if pos.x == line_length or (pos.x == 0 and curr_word_start):
        set_caret_line(pos.y + amnt)
        var x = 0 if !curr_word_start or next_word_start else line_length
        set_caret_column(x)

    var mv_caret = func():
        var caret_pos = Vector2i(get_caret_column(), get_caret_line())
        set_caret_column(caret_pos.x + amnt)

        if caret_pos.x == line_length or (caret_pos.x == 0 and curr_word_start):
            return false
        return true

    pos.x += amnt
    if get_word_under_caret().is_empty() or get_word_at_pos(pos).is_empty() or next_word_start:
        set_caret_column(get_caret_column() + amnt)

        while get_word_under_caret().is_empty():
            if !mv_caret.call():
                break

    while !get_word_under_caret().is_empty():
        if !mv_caret.call():
            break

    if get_caret_column() != 0:
        set_caret_column(get_caret_column() + (amnt * -1))


func enable_normal_mode() -> void: 
    caret_draw_when_editable_disabled = true
    command_line.editable = false
    command_line.text = ""
    deselect()
    grab_focus()

    caret_type = CaretType.CARET_TYPE_BLOCK
    pending_action = VimAction.NONE
    vim_mode = VimMode.NORMAL
    editable = false


func enable_insert_mode() -> void: 
    command_line.text = "-- INSERT --"
    caret_type = CaretType.CARET_TYPE_LINE
    vim_mode = VimMode.INSERT
    editable = true


func move_cursor(dir: Vector2i) -> void: 
    var col := get_caret_column() + dir.x
    var line := get_caret_line() + dir.y

    if vim_mode == VimMode.VISUAL:
        col = len(get_line(line)) if select_lines else col
        select(selection_start.y, selection_start.x, line, col)
        return

    set_caret_line(line, false, false, -1)
    set_caret_column(col, false)



func _on_command_line_text_submitted(new_text: String) -> void: 
    new_text = new_text.replace(":", "")
    new_text = new_text.strip_edges()
    var args = new_text.split(" ")

    match args[0]:
        "w", "wa", "write":
            save()

        "wq":
            save()
            get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)

        "q", "quit":
            get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)

        "e", "edit":
            edit_note.emit(args[1])

        _:
            command_line.text = "Command '%s' not found" % new_text

    enable_normal_mode()


func _on_command_line_command_cancelled() -> void: 
    vim_mode = VimMode.NORMAL
    editable = false
    grab_focus()



func save() -> void: 
    contents_changed = false
    save_note.emit(text)


func get_settings(): 
    return {
        "line_spacing" : line_spacing,
        "line_numbers" : line_numbers,
        "editor_mode" : editor_mode,
        "delay_time" : delay_time,
        "auto_save" : auto_save,
        "note_open" : note_open,
        "font": font,
    }


func reload_settings(): 
    if not command_line.text_submitted.is_connected(_on_command_line_text_submitted):
        command_line.text_submitted.connect(_on_command_line_text_submitted)

    if not command_line.command_cancelled.is_connected(_on_command_line_command_cancelled):
        command_line.command_cancelled.connect(_on_command_line_command_cancelled)

    gutters_draw_line_numbers = line_numbers
    add_theme_constant_override("line_spacing", line_spacing)
    add_theme_font_size_override("font_size", font_size)

    var f: SystemFont = load(AppTheme.FONT_PATH)
    var f_names = PackedStringArray([str(font)])
    f.font_names = f_names

    add_theme_font_override("font", f)
    text += ""

    editable = editor_mode != EditorMode.VIM
    caret_draw_when_editable_disabled = true
    command_line.text = ""
    deselect()
    grab_focus()

    caret_type = CaretType.CARET_TYPE_BLOCK
    vim_mode = VimMode.NORMAL


func get_default_setting(setting_name: String): 
    match setting_name: 
        "editor_mode"   : return DEFAULT_EDITOR_MODE
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


