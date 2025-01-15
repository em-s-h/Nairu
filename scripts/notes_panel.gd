class_name NotesPanel
extends Node


const DEFAULT_NOTE_BACKUP_DIRECTORY = "user://backups"
const DEFAULT_NOTE_DIRECTORY = "user://notes"

# Enums {{{
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

enum BackupOptions {
OFF,
ON_APP_OPEN,
ON_APP_CLOSE,
}
# }}}

signal edit_note(contents: String)
signal save_note_dates()
signal note_deleted(is_current: bool)
signal note_changed(new_note: String)

@export var NotificationDialogScene = preload("res://scenes/notification_dialog.tscn")
@export var NoteButtonScene = preload("res://scenes/note_button.tscn")

var backup_directory = DEFAULT_NOTE_BACKUP_DIRECTORY
var note_directory = DEFAULT_NOTE_DIRECTORY

var backup_option := BackupOptions.ON_APP_OPEN
var date_format := DateFormat.DAY_MONTH_YEAR
var note_sort := NoteSort.DATE_DESCENDING

var previous_note: String = ""
var current_note: String = ""

var open_previous_note := false
var keep_open := false

@onready var notes_container = $VBoxContainer/Notes/ScrollContainer/VBoxContainer


func _ready() -> void:
    # {{{
    create_note_dirs()
    var dir = DirAccess.open(note_directory)
    if dir != null:
        for f in dir.get_files():
            var note_button = NoteButtonScene.instantiate()
            var n_name = f.get_basename()

            note_button.initialize(n_name, "", date_format)
            notes_container.add_child(note_button)

            note_button.rename_note.connect(_on_note_button_rename_note)
            note_button.delete_note.connect(_on_note_button_delete_note)
            note_button.open_note.connect(_on_note_button_open_note)
        return

    var d = ErrorDialog.new()
    var msg = "Unable to access directory '%s'\n," % note_directory
    msg += "switching to default note directory.\n"
    msg += "Error: '%s'" % ErrorDialog.expand_error_code(DirAccess.get_open_error())

    d.dialog_text = msg
    add_child(d)

    note_directory = DEFAULT_NOTE_DIRECTORY
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
        var notif = NotificationDialogScene.instantiate()
        var msg = "Unable to open previous note,\n"
        msg += "Error: '%s'" % ErrorDialog.expand_error_code(FileAccess.get_open_error())

        notif.color = Color.RED
        notif.message = msg
        notif.duration = 6

        get_tree().root.get_node("Main").add_child(notif)
        return false

    note_changed.emit(previous_note.get_file().get_basename())
    edit_note.emit(file.get_as_text())
    current_note = previous_note

    return true
# }}}

func format_date(date, from, to) -> String:
    # {{{
    if "-" in date:
        date = date.split("-")
    else:
        date = date.split("/")

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

func create_notes_backup() -> void:
    # {{{
    create_note_dirs()
    var warn = func(mesg: String):
        var d = ErrorDialog.new()
        d.report_bug = false
        d.dialog_text = mesg
        d.ok_button_text = "Cancel backup"
        d.add_cancel_button("Restart backup")
        d.canceled.connect(create_notes_backup)
        add_child(d)
     
    var dir = DirAccess.open(backup_directory)
    if dir == null:
        var msg = "Unable to open note backup directory,\n"
        msg += "directory path: '%s'\n" % backup_directory
        msg += "Error: '%s'" % ErrorDialog.expand_error_code(DirAccess.get_open_error())
        warn.call(msg)
        return

    var date = Time.get_date_string_from_system()
    var zip_file = "%s/backup_%s.zip" % [backup_directory, date]

    # Creating zip here because unsure if ZIPPacker.open() creates it.
    var tmp = FileAccess.open(zip_file, FileAccess.ModeFlags.WRITE)
    if tmp == null:
        var msg = "Unable to create zip file for backup,\n"
        msg += "zip file path: '%s'\n" % zip_file
        msg += "Error: '%s'" % ErrorDialog.expand_error_code(FileAccess.get_open_error())
        warn.call(msg)
        return
    tmp.close()

    var ziper = ZIPPacker.new()
    var err = ziper.open(zip_file)

    if err != OK:
        var msg = "Unable to open zip file for backup\n"
        msg += "Error: '%s'" % ErrorDialog.expand_error_code(err)
        warn.call(msg)
        return

    dir = DirAccess.open(note_directory)
    if dir == null:
        var msg = "Unable to open notes directory for backup,\n"
        msg += "directory path: '%s'\n" % note_directory
        msg += "Error: '%s'" % ErrorDialog.expand_error_code(DirAccess.get_open_error())
        warn.call(msg)

        ziper.close()
        DirAccess.remove_absolute(zip_file)
        return

    for f in dir.get_files():
        var f_path = "%s/%s" % [note_directory, f]
        var contents = FileAccess.get_file_as_string(f_path)

        if !contents.is_empty() || FileAccess.get_open_error() == OK:
            ziper.start_file(f)
            ziper.write_file(contents.to_utf8_buffer())
            ziper.close_file()
            continue

        var msg = "Unable to read note's contents for backup,\n"
        msg += "note file path: '%s'\n" % f_path
        msg += "Error: '%s'" % ErrorDialog.expand_error_code(FileAccess.get_open_error())
        warn.call(msg)

        ziper.close()
        DirAccess.remove_absolute(zip_file)
        return

    ziper.close()
# }}}

func create_note_dirs() -> void:
    # {{{
    var dir = DirAccess.open("user://")

    if !dir.dir_exists("./backups"):
        dir.make_dir("./backups")

    if !dir.dir_exists("./notes"):
        dir.make_dir("./notes")
# }}}


func get_settings():
    # {{{
    return {
        "backup_directory" : backup_directory,
        "note_directory" : note_directory,
        "open_previous_note": open_previous_note,
        "previous_note" : current_note,
        "backup_option" : backup_option,
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
    save_note_dates.emit()
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
        var d = ErrorDialog.new()
        var msg = "Unable to rename note '%s' to '%s'.\n" % [old_name, new_name]
        msg += "Note path: '%s',\n" % from
        msg += "Error: '%s'" % ErrorDialog.expand_error_code(res)

        d.dialog_text = msg
        add_child(d)
        return

    for n in notes_container.get_children():
        if n.note_name == old_name:
            n.set_note_name(new_name)

    if old_name == current_note.get_file().get_basename():
        current_note = make_note_path(new_name)
        note_changed.emit(new_name)
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
        var d = ErrorDialog.new()
        var msg = "Unable to open note '%s'.\n" % note_name
        msg += "Note path: '%s',\n" % path
        msg += "Error: '%s'" % ErrorDialog.expand_error_code(FileAccess.get_open_error())

        d.dialog_text = msg
        add_child(d)
        return

    edit_note.emit(file.get_as_text())
    note_changed.emit(title)
    current_note = path
# }}}

func _on_note_button_delete_note(note_name):
    # {{{
    var path = make_note_path(note_name)
    var res = DirAccess.remove_absolute(path)

    if res != OK:
        var d = ErrorDialog.new()
        var msg = "Unable to delete note '%s'.\n" % note_name
        msg += "Note path: '%s',\n" % path
        msg += "Error: '%s'" % ErrorDialog.expand_error_code(res)

        d.dialog_text = msg
        add_child(d)
        return

    for n in notes_container.get_children():
        if n.note_name == note_name:
            n.queue_free()
            note_deleted.emit(path == current_note)
            note_changed.emit("")
            return
# }}}


func _on_text_editor_save_note(note_contents):
    # {{{
    prints("Saving note...")

    var file = FileAccess.open(current_note, FileAccess.WRITE)
    if file == null:
        var d = ErrorDialog.new()
        var msg = "Unable to write note contents to file.\n"
        msg += "Note path: '%s'\n" % current_note
        msg += "Error: '%s'" % ErrorDialog.expand_error_code(FileAccess.get_open_error())

        d.dialog_text = msg
        add_child(d)
        return

    file.store_string(note_contents)
    file.close()

    var notif = NotificationDialogScene.instantiate()
    notif.message = "Note saved!"
    notif.color = Color.GREEN
    notif.duration = 1.25
    get_tree().root.get_node("Main").add_child(notif)
# }}}


