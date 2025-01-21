class_name SettingsWindow
extends Window


## Represents the currently open settings panel
var current_section := "TextEditor"


func _ready() -> void:
    # {{{
    title = "Settings"
# }}}

func reload_settings(conf: ConfigFile):
    # {{{
    for c in $TabContainer.get_children():
        if c is SettingsPanel:
            var node_name = c.represents_node
            var sect: String = ""

            for s in conf.get_sections():
                if s.get_file() == node_name:
                    sect = s

            if sect.is_empty():
                printerr("Unable to find section for node '%s', returning" % node_name)
                close_requested.emit()
                return

            for k in conf.get_section_keys(sect):
                c.set_setting(k, conf.get_value(sect, k))
# }}}

func _on_tab_container_tab_changed(tab: int) -> void:
    # {{{
    var tab_c = $TabContainer.get_tab_control(tab)
    var s = Vector2i(size.x, int(tab_c.custom_minimum_size.y) + 61)
    size = s

    if tab_c is SettingsPanel:
        current_section = tab_c.represents_node
# }}}

func _on_exit_pressed() -> void:
    close_requested.emit()
