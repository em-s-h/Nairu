class_name Main
extends Control


const WINDOW_DEFAULT_SIZE = Vector2(720, 822)


@onready var settings_panel: SettingsPanel = $SettingsPanel
@onready var text_editor: TextEditor = $VScrollBar/TextEdit
@onready var notes_panel: NotesPanel = $NotesPanel

var settings_panel_detached := false
var settings_panel_open := false

var notes_panel_detached := false
var notes_panel_open := false


func _ready() -> void:
    notes_panel.text_editor = text_editor
    text_editor.notes_panel = notes_panel

    # settings_panel.load_settings()
    var note = notes_panel.get_previous_note()
    if len(note) == 0:
        note = notes_panel.create_new_note()
    # text_editor.edit_note(note)


func _process(delta: float) -> void:
    pass


func open_note_panel():
    pass


func close_note_panel():
    pass


func open_settings_panel():
    pass


func close_settings_panel():
    pass


# Handle Wayland
func resize_window(direction, delta):
    # t += delta
    # t1 += delta * 0.7
    #
    # if t >= 1 and t1 <= 1:
    #     var target_win_size = WINDOW_DEFAULT_SIZE + Vector2(0, 50)
    #
    #     var new_win_size = WINDOW_DEFAULT_SIZE.lerp(target_win_size, t1)
    #     new_win_size = clamp(new_win_size, WINDOW_DEFAULT_SIZE, target_win_size)
    #
    #     DisplayServer.window_set_size(new_win_size)
    pass


func detach_notes_panel():
    pass


func detach_settings_panel():
    pass
