class_name NotesPanel
extends Node


const DEFAULT_NOTE_DIRECTORY = "user://"


signal open_note(note)


var note_directory = DEFAULT_NOTE_DIRECTORY
var previous_note: String
var text_editor


## Return the file path of the last edited note.
##
## Returns the file path of the last note being edited before the app was closed,
## if no note was being edited returns an empty string.
func get_previous_note() -> String:
    return ""


## Return the file path of a new note.
func create_new_note() -> String:
    return ""


func rename_note():
    pass


# func save_note(note):
#     pass


func delete_note():
    pass
