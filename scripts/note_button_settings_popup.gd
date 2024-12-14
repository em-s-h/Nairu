extends Control


signal rename()
signal save_to()
signal delete()


func _on_rename_pressed() -> void:
    rename.emit()

    
func _on_save_to_pressed() -> void:
    save_to.emit()


func _on_delete_pressed() -> void:
    delete.emit()
