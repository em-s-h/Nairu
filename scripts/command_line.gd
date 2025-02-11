class_name CommandLine
extends LineEdit


signal command_cancelled()


func _on_text_changed(new_text: String) -> void: 
    if new_text.is_empty():
        command_cancelled.emit()
        editable = false


func _on_focus_exited() -> void: 
    text = ""

