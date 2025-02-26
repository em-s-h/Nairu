class_name NoteButton
extends Button


const TITLE_MAX_CHARACTERS := 15

signal open_note(file_name)
signal rename_note(old_name, new_name)
signal delete_note(file_name)

@onready var SettingsPopupScene = preload("res://scenes/note_button_settings_popup.tscn")
var settings_popup

@onready var title = $HBoxContainer/VBoxContainer/Title
@onready var date = $HBoxContainer/VBoxContainer/CreationDate

var note_name := ""
var creation_date := ""
var current_date_format := NotesPanel.DateFormat.DAY_MONTH_YEAR

var settings_popup_open := false
var open_settings_popup := false
var warning_popup_open := false


func _ready() -> void:
    title.text = note_name
    date.text = creation_date
    var dt = creation_date.split(',')
    date.visible_characters = len(dt[0])

func _process(_delta: float) -> void:
    if !has_node("NoteButtonSettingsPopup"):
        return

    var down = "_down"
    # Popup's position is 8px bellow the button after the close animation.
    if global_position.y + size.y + settings_popup.size.y + 8 > get_window().size.y:
        down = ""

    if open_settings_popup and !settings_popup_open:
        settings_popup.open(down)

    elif !open_settings_popup and settings_popup_open:
        settings_popup.close(down)

func initialize(_name, _date, _date_format):
    note_name = _name
    name = _name

    creation_date = _date
    current_date_format = _date_format

func set_note_name(new_name: String):
    title.text = new_name
    note_name = new_name
    name = new_name

func get_settings():
    return {
        "creation_date" : creation_date,
        "current_date_format" : current_date_format,
    }

func reload_settings():
    if creation_date.is_empty():
        var pa = get_tree().root.get_node("Main/HBoxContainer/NotesPanel")
        if pa == null:
            printerr("This func is called after '_ready' in Main, thus NotesPanel should be loaded.")

        var d = Time.get_date_string_from_system()
        d += "," + Time.get_time_string_from_system()
        creation_date = pa.format_date(d, NotesPanel.DateFormat.YEAR_MONTH_DAY, pa.date_format)

    date.text = creation_date
    var dt = creation_date.split(',')

    # Forces text to update
    date.visible_characters = 2
    date.visible_characters = len(dt[0])


func toggle_settings_popup() -> void:
    # $HBoxContainer/NoteSettingsButton.disabled = true
    open_settings_popup = !open_settings_popup
    if !open_settings_popup:
        return

    settings_popup = SettingsPopupScene.instantiate()
    add_child(settings_popup)

    settings_popup.get_node("AnimationPlayer").animation_finished.connect(_on_animation_player_animation_finished)
    settings_popup.rename.connect(_on_note_button_settings_popup_rename)
    settings_popup.delete.connect(_on_note_button_settings_popup_delete)

func _on_pressed() -> void:
    open_note.emit(note_name)

func _on_focus_exited() -> void:
    if settings_popup_open:
        toggle_settings_popup()

func _on_gui_input(event: InputEvent) -> void:
    var r_click = InputEventMouseButton.new()
    r_click.button_index = MOUSE_BUTTON_RIGHT

    if event.is_match(r_click) and event.is_released():
        toggle_settings_popup()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
    match anim_name:
        "open", "open_down":
            # $HBoxContainer/NoteSettingsButton.disabled = false
            settings_popup_open = true

            settings_popup.original_position = settings_popup.global_position
            settings_popup.top_level = true
            settings_popup.global_position = settings_popup.original_position
            settings_popup.call_deferred("grab_focus")

        "close", "close_down":
            # $HBoxContainer/NoteSettingsButton.disabled = false
            settings_popup_open = false
            settings_popup.queue_free()


func _on_title_gui_input(event: InputEvent) -> void:
    var l_click = InputEventMouseButton.new()
    l_click.button_index = MOUSE_BUTTON_LEFT

    if event.is_match(l_click) and event.double_click:
        title.editable = true
        title.grab_focus()

func _on_title_text_changed(new_text: String) -> void:
    title.expand_to_text_length = len(new_text) <= TITLE_MAX_CHARACTERS
    title.custom_minimum_size = Vector2(138, 0)

func _on_title_text_submitted(new_text: String) -> void:
    title.editable = false
    rename_note.emit(note_name, new_text)


func _on_note_button_settings_popup_delete() -> void:
    toggle_settings_popup()

    var confirm_dialog = ConfirmationDialog.new()

    confirm_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
    confirm_dialog.theme = load(AppTheme.THEME_PATH)

    confirm_dialog.title = "Confirm"
    confirm_dialog.dialog_text = "Delete note '%s'?" % note_name
    confirm_dialog.ok_button_text = "Delete"

    confirm_dialog.get_ok_button().pressed.connect(_on_confirm_dialog_confirm)

    add_child(confirm_dialog)
    confirm_dialog.show()
    for c in confirm_dialog.get_children(true):
        if c is Panel: c.remove_theme_stylebox_override("panel")
        if c is Label: c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _on_confirm_dialog_confirm():
    delete_note.emit(note_name)

func _on_note_button_settings_popup_rename() -> void:
    toggle_settings_popup()
    title.editable = true
    title.grab_focus()

func _on_note_button_settings_popup_focus_exited() -> void:
    toggle_settings_popup()
