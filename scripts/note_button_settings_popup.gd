class_name NoteButtonSettingsPopup
extends Panel


signal rename()
signal delete()

@onready var animation_player: AnimationPlayer = $AnimationPlayer
var original_position := Vector2.ZERO


func open(down: String) -> void:
    animation_player.play("open%s" % down)


func close(down: String) -> void:
    top_level = false
    global_position = original_position
    # Can't play 'open' backwards due to 'animation_finished' callback
    animation_player.play("close%s" % down)


func _on_rename_pressed() -> void:
    rename.emit()


func _on_delete_pressed() -> void:
    delete.emit()
