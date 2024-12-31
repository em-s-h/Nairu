class_name NoteButton
extends Button


const TITLE_MAX_CHARACTERS := 15

signal open_note(file_name)
signal rename_note(old_name, new_name)
signal delete_note(file_name)

@onready var settings_popup = $NoteButtonSettingsPopup
@onready var title = $HBoxContainer/VBoxContainer/Title
@onready var date = $HBoxContainer/VBoxContainer/CreationDate

var note_name := ""
var creation_date := ""
var current_date_format := NotesPanel.DateFormat.DAY_MONTH_YEAR

var settings_popup_global_pos: Vector2
var settings_popup_open := false
var open_settings_popup := false
var warning_popup_open := false


func _ready() -> void:
    # {{{
    title.text = note_name
    date.text = creation_date
# }}}

func _process(delta: float) -> void:
    # {{{
    if open_settings_popup and !settings_popup_open:
        $AnimationPlayer.play("open_settings")
        move_settings_popup_y(-122, delta)

    elif !open_settings_popup and settings_popup_open:
        $AnimationPlayer.play("close_settings")
        move_settings_popup_y(122, delta)
# }}}

func initialize(_name, _date, _date_format):
    # {{{
    note_name = _name
    name = _name

    creation_date = _date
    current_date_format = _date_format
# }}}

## Move settings popup on the y axis
func move_settings_popup_y(quant, delta):
    # {{{
    var positive = quant > 0

    var weight = $AnimationPlayer.current_animation_position / $AnimationPlayer.current_animation_length
    var start = settings_popup_global_pos.y

    if global_position.y - settings_popup.size.y < 0:
        positive = !positive
        quant = size.y + 8
        quant *= 1 if positive else -1

    var target = start + quant
    weight += delta * 3

    var min_pos
    var max_pos

    if positive:
        max_pos = target
        min_pos = start
    else:
        max_pos = start
        min_pos = target

    if settings_popup.global_position.y != target:
        var new_pos = lerp(start, target, weight)
        new_pos = Vector2(settings_popup_global_pos.x, clampf(new_pos, min_pos, max_pos))
        settings_popup.global_position = new_pos
# }}}

func set_note_name(new_name: String):
    # {{{
    title.text = new_name
    note_name = new_name
    name = new_name
# }}}

func get_settings():
    # {{{
    return {
        "creation_date" : creation_date,
        "current_date_format" : current_date_format,
    }
# }}}

func reload_settings():
    # {{{
    $HBoxContainer/VBoxContainer/CreationDate.text = creation_date
# }}}


func _on_pressed() -> void:
    # {{{
    open_note.emit(note_name)
# }}}

func _on_focus_exited() -> void:
    # {{{
    if settings_popup_open:
        $AnimationPlayer.play("close_settings")
# }}}

func _on_gui_input(event: InputEvent) -> void:
    # {{{
    var r_click = InputEventMouseButton.new()
    r_click.button_index = MOUSE_BUTTON_RIGHT

    if event.is_match(r_click) and event.is_released():
        $AnimationPlayer.play("open_settings")
# }}}

func _on_note_settings_button_pressed() -> void:
    # {{{
    if !settings_popup.top_level:
        settings_popup_global_pos = settings_popup.global_position
        settings_popup.top_level = true

    open_settings_popup = !open_settings_popup
# }}}

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
    # {{{
    match anim_name:
        "open_settings":
            settings_popup_open = true
            settings_popup.grab_focus()
            _update_settings_popup_global_pos()

        "close_settings":
            settings_popup_open = false
            _update_settings_popup_global_pos()
# }}}

func _update_settings_popup_global_pos():
    # {{{
    settings_popup_global_pos = settings_popup.global_position
# }}}


func _on_title_gui_input(event: InputEvent) -> void:
    # {{{
    var l_click = InputEventMouseButton.new()
    l_click.button_index = MOUSE_BUTTON_LEFT

    if event.is_match(l_click) and event.double_click:
        title.editable = true
        title.grab_focus()
# }}}

func _on_title_text_changed(new_text: String) -> void:
    # {{{
    title.expand_to_text_length = len(new_text) <= TITLE_MAX_CHARACTERS
    title.custom_minimum_size = Vector2(138, 0)
# }}}

func _on_title_focus_exited() -> void:
    # {{{
    title.editable = false
# }}}

func _on_title_text_submitted(new_text: String) -> void:
    # {{{
    title.editable = false
    rename_note.emit(note_name, new_text)
# }}}


func _on_note_button_settings_popup_delete() -> void:
    # {{{
    open_settings_popup = false
    $AnimationPlayer.play("close_settings")

    var confirm_dialog = ConfirmationDialog.new()

    confirm_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
    confirm_dialog.visible = true
    confirm_dialog.theme = load("res://themes/default.tres")

    confirm_dialog.title = "Confirm"
    confirm_dialog.dialog_text = "Delete note '%s'?" % note_name
    confirm_dialog.ok_button_text = "Delete"

    confirm_dialog.get_ok_button().pressed.connect(_on_confirm_dialog_confirm)

    add_child(confirm_dialog)
    for c in confirm_dialog.get_children(true):
        if c is Panel: c.remove_theme_stylebox_override("panel")
# }}}

func _on_confirm_dialog_confirm():
    # {{{
    delete_note.emit(note_name)
# }}}

func _on_note_button_settings_popup_rename() -> void:
    # {{{
    $AnimationPlayer.play("close_settings")
    title.editable = true
    title.grab_focus()
# }}}

func _on_note_button_settings_popup_save_to() -> void:
    # {{{
    $AnimationPlayer.play("close_settings")
    printerr("To-do: get file dialog and make a custom path")
# }}}
