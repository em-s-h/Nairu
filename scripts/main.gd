class_name Main
extends Panel


@onready var settings: Settings = $Settings
@onready var text_editor: TextEditor = $HBoxContainer/VBoxContainer/TextEditor
@onready var notes_panel: NotesPanel = $HBoxContainer/NotesPanel

@onready var current_window_size := get_window().size as Vector2

var top_panel_size
var notes_panel_size

var settings_open := false
var title := "Nairu"

var notes_panel_open := false
var open_notes_panel := false

var top_panel_open := false
var open_top_panel := false
var is_fullscreen := false


func _ready() -> void: # {{{
    get_tree().set_auto_accept_quit(false)
    get_window().size_changed.connect(_on_window_size_changed)

    top_panel_size = $HBoxContainer/VBoxContainer/TopPanel.custom_minimum_size
    notes_panel_size = notes_panel.custom_minimum_size

    notes_panel.edit_note.connect(text_editor._on_notes_panel_edit_note)
    notes_panel.note_deleted.connect(text_editor._on_notes_panel_note_deleted)
    notes_panel.save_note_dates.connect(settings._on_notes_panel_save_note_dates)
    text_editor.save_note.connect(notes_panel._on_text_editor_save_note)
    notes_panel.text_editor = text_editor

    var sav = func(_a): if "*" in title: change_title(title.erase(len(title)-1, 1))
    var txt = func(): if not "*" in title: change_title("%s*" % title)
    text_editor.text_changed.connect(txt)
    text_editor.save_note.connect(sav)
    notes_panel.note_changed.connect(change_title)

    settings.load_settings()
    notes_panel.open_last_edited_note()

    if notes_panel.keep_open:
        _on_notes_panel_button_pressed()

    if notes_panel.backup_option == notes_panel.BackupOptions.ON_APP_OPEN:
        notes_panel.create_notes_backup()
# }}}

func _notification(what: int) -> void: # {{{
    if what != NOTIFICATION_WM_CLOSE_REQUEST:
        return

    settings.save_settings()

    if text_editor.contents_changed:
        var d = ConfirmationDialog.new()
        add_child(d)

        var conf = func():
            text_editor.save()
            get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)

        var exit = func(a):
            if a == "exit":
                get_tree().quit()

        d.custom_action.connect(exit)
        d.confirmed.connect(conf)

        d.title = "Changes not saved!"
        d.theme = load("res://themes/default.tres")
        for c in d.get_children(true):
            if c is Panel: c.remove_theme_stylebox_override("panel")
            if c is Label: c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

        d.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
        d.ok_button_text = "Save"

        var msg = "Are you sure you want to exit?\n"
        msg += "You have unsaved changes."
        d.dialog_text = msg

        d.add_button("Exit", false, "exit")
        d.show()
        return

    if notes_panel.backup_option == notes_panel.BackupOptions.ON_APP_CLOSE:
        notes_panel.create_notes_backup()

    get_tree().quit()
# }}}

func _process(delta: float) -> void: # {{{
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


func change_title(new_title: String) -> void: # {{{
    if new_title.is_empty():
        new_title = "Nairu"

    get_window().title = new_title
    title = new_title
# }}}

func resize_window(direction, quant, delta): # {{{
    var mode = get_window().mode
    if mode == Window.MODE_FULLSCREEN or mode == Window.MODE_EXCLUSIVE_FULLSCREEN \
       or mode == Window.MODE_MAXIMIZED:
        return

    var positive = quant > 0

    match direction:
        Vector2.UP, Vector2.DOWN: quant = Vector2(0, quant)
        Vector2.LEFT, Vector2.RIGHT: quant = Vector2(quant, 0)

    var weight = $AnimationPlayer.current_animation_position / $AnimationPlayer.current_animation_length
    var target_win_size = current_window_size + quant

    var screen_size = DisplayServer.screen_get_size()
    if target_win_size.x > screen_size.x or target_win_size.y > screen_size.y:
        return

    weight += delta * 3
    var min_size
    var max_size

    if positive:
        min_size = current_window_size
        max_size = target_win_size
    elif !positive:
        max_size = current_window_size
        min_size = target_win_size

    if target_win_size as Vector2i != get_window().size:
        var new_win_size = current_window_size.lerp(target_win_size, weight)
        new_win_size = clamp(new_win_size, min_size, max_size)

        get_window().size = new_win_size
# }}}

func _on_window_size_changed() -> void: # {{{
    var mode = get_window().mode

    # Update window size right after leaving fullscreen
    if is_fullscreen and mode == Window.MODE_WINDOWED:
        current_window_size = get_window().size

    is_fullscreen = mode == Window.MODE_MAXIMIZED or mode == Window.MODE_FULLSCREEN \
                    or mode == Window.MODE_EXCLUSIVE_FULLSCREEN

    get_viewport().gui_embed_subwindows = is_fullscreen
# }}}


func _on_top_panel_button_pressed() -> void: # {{{
    open_top_panel = !open_top_panel
    $HBoxContainer/VBoxContainer/TopPanelButton.release_focus()
    _update_current_window_size()
# }}}

func _on_notes_panel_button_pressed() -> void: # {{{
    open_notes_panel = !open_notes_panel
    $HBoxContainer/VBoxContainer/TopPanel/NotesPanelButton.release_focus()
    _update_current_window_size()
# }}}

func _on_settings_window_button_pressed() -> void: # {{{
    $HBoxContainer/VBoxContainer/TopPanel/SettingsWindowButton.release_focus()
    settings.open_settings()
# }}}


func _on_animation_player_animation_finished(anim_name: StringName) -> void: # {{{
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

func _update_current_window_size(): # {{{
    current_window_size = get_window().size
# }}}
