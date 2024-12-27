class_name NotesPanel
extends Node


const DEFAULT_NOTE_DIRECTORY = "user://notes"

enum DateFormat {
    YEAR_MONTH_DAY,
    DAY_MONTH_YEAR,
}

enum NoteSort {
    DATE_DESCENDING,
    DATE_ASCENDING,
    NAME_DESCENDING,
    NAME_ASCENDING,
}

signal edit_note(contents: String)
signal note_deleted(is_current: bool)

var NoteButtonScene = preload("res://scenes/note_button.tscn")

var note_directory = DEFAULT_NOTE_DIRECTORY
var date_format := DateFormat.DAY_MONTH_YEAR
var note_sort := NoteSort.DATE_DESCENDING

var previous_note: String = ""
var current_note: String = ""
var keep_open := false

@onready var notes_container = $VBoxContainer/Notes/ScrollContainer/VBoxContainer
# var notes = []


func _ready() -> void:
    # {{{
    var dir = DirAccess.open(note_directory)
    if dir != null:
        for f in dir.get_files():
            var note_button = NoteButtonScene.instantiate()
            var n_name = f.get_file().get_basename()

            note_button.initialize(n_name, "", date_format)
            notes_container.add_child(note_button)

            note_button.rename_note.connect(_on_note_button_rename_note)
            note_button.delete_note.connect(_on_note_button_delete_note)
            note_button.open_note.connect(_on_note_button_open_note)
        return

    printerr("Unable to access directory '%s', using default directory." % note_directory)
    printerr("Err: '%s'" % DirAccess.get_open_error())

    note_directory = DEFAULT_NOTE_DIRECTORY
    dir = DirAccess.open("user://")
    if !dir.dir_exists("./notes"):
        dir.make_dir("./notes")
        return
# }}}

## Open the last edited note.
##
## Open the last note being edited before the app was closed,
## if no note was being edited returns false.
func open_last_edited_note() -> bool:
    # {{{
    if previous_note == "":
        return false

    var file = FileAccess.open(previous_note, FileAccess.READ)
    if file == null:
        printerr("Unable to open previous note '%s'." % previous_note)
        printerr("Err: '%s'" % FileAccess.get_open_error())
        return false

    DisplayServer.window_set_title(previous_note.get_file().get_basename())
    edit_note.emit(file.get_as_text())
    current_note = previous_note

    return true
# }}}

func format_date(date, from, to) -> String:
    # {{{
    date = date.split("-")

    if from == to:
        return "/".join(date)

    # There are only 2 options, and they mirror each other: YMD DMY
    date.reverse()

    return "/".join(date)
# }}}

func sort_notes():
    # {{{
    var notes = []
    for n in notes_container.get_children():
        notes.append(n)
        notes_container.remove_child(n)

    notes.sort_custom(
    func (a, b):
        match note_sort:
            NoteSort.NAME_ASCENDING:
                return a.note_name.naturalnocasecmp_to(b.note_name) <= 0
            NoteSort.NAME_DESCENDING:
                return a.note_name.naturalnocasecmp_to(b.note_name) >= 0
            NoteSort.DATE_ASCENDING:
                return a.creation_date.naturalnocasecmp_to(b.creation_date) <= 0
            NoteSort.DATE_DESCENDING:
                return a.creation_date.naturalnocasecmp_to(b.creation_date) >= 0
    )

    for n in notes:
        notes_container.add_child(n)
# }}}


func get_settings():
    # {{{
    return {
        "note_directory" : note_directory,
        "previous_note" : current_note,
        "date_format" : date_format,
        "note_sort" : note_sort,
        "keep_open" : keep_open,
    }
# }}}

func reload_settings():
    # {{{
    $VBoxContainer/Opts/VBoxContainer/Sort.select(note_sort as int)
    sort_notes()
# }}}


func make_note_path(n_name) -> String: return str(note_directory, "/", n_name, ".txt")
func open_panel(): $AnimationPlayer.play("open_panel")
func close_panel(): $AnimationPlayer.play_backwards("open_panel")


func _on_create_pressed() -> void:
    # {{{
    prints("Creating new note...")
    var note = str(note_directory, "/", "new_note")
    var note_id = 0

    while FileAccess.file_exists(str(note, ".txt")):
        note_id += 1
        note = str(note_directory, "new_note", note_id)

    current_note = str(note, ".txt")

    var file = FileAccess.open(current_note, FileAccess.WRITE)
    file.store_string("")
    file.close()

    var note_button = NoteButtonScene.instantiate()
    var date = Time.get_date_string_from_system()

    date = format_date(date, DateFormat.YEAR_MONTH_DAY, date_format)
    note_button.initialize(note.get_file(), date, date_format)
    notes_container.add_child(note_button)

    note_button.rename_note.connect(_on_note_button_rename_note)
    note_button.delete_note.connect(_on_note_button_delete_note)
    note_button.open_note.connect(_on_note_button_open_note)
    sort_notes()
# }}}

func _on_sort_item_selected(index: int) -> void:
    # {{{
    note_sort = $VBoxContainer/Opts/VBoxContainer/Sort.get_item_id(index) as NoteSort
    sort_notes()
# }}}


func _on_note_button_rename_note(old_name, new_name: String):
    # {{{
    new_name = new_name.validate_filename()
    var tmp_name = new_name

    var is_unique = func (n_name) -> bool:
        for n in notes_container.get_children():
            if n.note_name == n_name:
                return false
        return true

    var id = 2
    while !is_unique.call(tmp_name):
        tmp_name = str(new_name, id)
        id += 1

    new_name = tmp_name

    var from = make_note_path(old_name)
    var to = make_note_path(new_name)
    var res = DirAccess.rename_absolute(from, to)

    if res != OK:
        printerr("Unable to rename file '%s' to '%s'." % [from, to])
        printerr("Err: '%s'" % res)
        return

    for n in notes_container.get_children():
        if n.note_name == old_name:
            n.set_note_name(new_name)

    if old_name == current_note.get_file().get_basename():
        DisplayServer.window_set_title(new_name)
        current_note = make_note_path(new_name)
    sort_notes()
# }}}

func _on_note_button_open_note(note_name):
    # {{{
    prints("Opening note...")
    if note_name == current_note.get_basename():
        prints("Note already open.")
        return

    var title = note_name
    var path = make_note_path(note_name)
    var file = FileAccess.open(path, FileAccess.READ)

    if file == null:
        printerr("Unable to open note '%s'." % note_name)
        printerr("Err: '%s'" % FileAccess.get_open_error())
        return

    DisplayServer.window_set_title(title)
    edit_note.emit(file.get_as_text())
    current_note = path
# }}}

func _on_note_button_delete_note(note_name):
    # {{{
    var path = make_note_path(note_name)
    var res = DirAccess.remove_absolute(path)

    if res != OK:
        printerr("Unable to delete note '%s'" % note_name)
        printerr("Err: '%s'" % res)
        return

    for n in notes_container.get_children():
        if n.note_name == note_name:
            n.queue_free()
            note_deleted.emit(path == current_note)
            return
# }}}


func _on_text_editor_save_note(note_contents):
    # {{{
    prints("Saving note...")

    var file = FileAccess.open(current_note, FileAccess.WRITE)
    if file == null:
        prints("Unable to open file '%s' for saving." % current_note)
        prints("Err: '%s'" % FileAccess.get_open_error())
        return

    file.store_string(note_contents)
    file.close()
# }}}


