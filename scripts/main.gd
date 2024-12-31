class_name Main
extends Control


@onready var settings_window: SettingsWindow = $HBoxContainer/SettingsWindow
@onready var text_editor: TextEditor = $HBoxContainer/VBoxContainer/TextEditor
@onready var notes_panel: NotesPanel = $HBoxContainer/NotesPanel

@onready var current_window_size := DisplayServer.window_get_size() as Vector2

var top_panel_size
var notes_panel_size

var settings_window_open := false

var notes_panel_open := false
var open_notes_panel := false

var top_panel_open := false
var open_top_panel := false


func _ready() -> void:
    # {{{
    top_panel_size = $HBoxContainer/VBoxContainer/TopPanel.custom_minimum_size
    notes_panel_size = notes_panel.custom_minimum_size

    notes_panel.edit_note.connect(text_editor._on_notes_panel_edit_note)
    notes_panel.note_deleted.connect(text_editor._on_notes_panel_note_deleted)
    notes_panel.save_note_dates.connect(settings_window._on_notes_panel_save_note_dates)
    text_editor.save_note.connect(notes_panel._on_text_editor_save_note)

    settings_window.load_settings()
    notes_panel.open_last_edited_note()

    if notes_panel.keep_open:
        _on_notes_panel_button_pressed()
# }}}

func _notification(what: int) -> void:
    # {{{
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        # Put warning dialogue
        text_editor.save()
        settings_window.save_settings()
# }}}

func _process(delta: float) -> void:
    # {{{
    if open_top_panel and !top_panel_open:
        $AnimationPlayer.play("open_top_panel")
        resize_window(Vector2.UP, top_panel_size.y, delta)

    elif !open_top_panel and top_panel_open:
        $AnimationPlayer.play("close_top_panel")
        resize_window(Vector2.DOWN, -top_panel_size.y, delta)

    if open_notes_panel and !notes_panel_open:
        $AnimationPlayer.play("open_notes_panel")
        resize_window(Vector2.LEFT, notes_panel_size.x, delta)
        notes_panel.open_panel()

    elif !open_notes_panel and notes_panel_open:
        $AnimationPlayer.play("close_notes_panel")
        resize_window(Vector2.RIGHT, -notes_panel_size.x, delta)
        notes_panel.close_panel()
# }}}

func resize_window(direction, quant, delta):
    # {{{
    var positive = quant > 0

    match direction:
        Vector2.UP, Vector2.DOWN: quant = Vector2(0, quant)
        Vector2.LEFT, Vector2.RIGHT: quant = Vector2(quant, 0)

    var weight = $AnimationPlayer.current_animation_position / $AnimationPlayer.current_animation_length
    var target_win_size = current_window_size + quant
    weight += delta * 3

    var min_size
    var max_size

    if positive:
        min_size = current_window_size
        max_size = target_win_size
    elif !positive:
        max_size = current_window_size
        min_size = target_win_size

    if target_win_size as Vector2i != DisplayServer.window_get_size():
        var new_win_size = current_window_size.lerp(target_win_size, weight)
        new_win_size = clamp(new_win_size, min_size, max_size)

        DisplayServer.window_set_size(new_win_size)
# }}}

func _on_settings_window_close_requested() -> void:
    # {{{
    settings_window.gui_release_focus()
    settings_window.hide()
# }}}


func _on_top_panel_button_pressed() -> void:
    # {{{
    open_top_panel = !open_top_panel
    $HBoxContainer/VBoxContainer/TopPanelButton.release_focus()
# }}}

func _on_notes_panel_button_pressed() -> void:
    # {{{
    open_notes_panel = !open_notes_panel
    $HBoxContainer/VBoxContainer/TopPanel/NotesPanelButton.release_focus()
# }}}

func _on_settings_window_button_pressed() -> void:
    # {{{
    settings_window.show()
    settings_window.grab_focus()
    $HBoxContainer/VBoxContainer/TopPanel/SettingsWindowButton.release_focus()
# }}}


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
    # {{{
    match anim_name:
        "open_top_panel":
            top_panel_open = true

        "close_top_panel":
            top_panel_open = false

        "open_notes_panel":
            notes_panel_open = true

        "close_notes_panel":
            notes_panel_open = false

    _update_current_window_size()
# }}}

func _update_current_window_size():
    # {{{
    current_window_size = DisplayServer.window_get_size()
# }}}

