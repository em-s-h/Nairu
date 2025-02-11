# I just want some code completion
class_name SettingsPanel
extends Panel


signal setting_changed(key: String, val)

## The name of the node that this settings panel represents
var represents_node: String = ""
var settings: Settings


func set_setting(key: String, val) -> void: 
    var node_name = key.to_pascal_case()
    var node = get_node_or_null("ScrollContainer/GridContainer/%s" % node_name)

    if node == null:
        prints("Invalid node: '%s', returning." % node_name)
        return

    if node is CheckButton:
        node.set_pressed_no_signal(val)

    elif node is LineEdit:
        node.text = str(val)

    elif node is OptionButton:
        node.select(val)

    elif node is ColorPickerButton:
        node.color = val

    elif node is Button:
        node.text = str(val)

