class_name NoteButtonSettingsPopup
extends Panel


signal rename()
signal save_to()
signal delete()

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func open(down: String) -> void:
    if animation_player.is_playing():
        return
    animation_player.play("open%s" % down)


func close(down: String) -> void:
    # Can't play 'open' backwards due to 'animation_finished' callback
    animation_player.play("close%s" % down)


func _on_rename_pressed() -> void:
    rename.emit()


func _on_save_to_pressed() -> void:
    save_to.emit()


func _on_delete_pressed() -> void:
    delete.emit()
