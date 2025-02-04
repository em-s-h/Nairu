class_name AppTheme
extends Node


const DEFAULT_THEME_PRESET      := ThemePresets.LIGHT
const LIGHT_THEME_BACKGROUND    := Color.WHITE
const LIGHT_THEME_COMPLEMENTARY := Color.BLACK
const LIGHT_THEME_SUCCESS       := Color.GREEN
const LIGHT_THEME_WARNING       := Color.YELLOW
const LIGHT_THEME_ERROR         := Color.RED
const LIGHT_THEME_ACCENT        := Color.SKY_BLUE
const LIGHT_THEME_FONT_COLOR    := Color.BLACK

enum ThemePresets {
    CUSTOM,
    LIGHT,
    DARK,
}

var theme_background    := LIGHT_THEME_BACKGROUND
var theme_complementary := LIGHT_THEME_COMPLEMENTARY
var theme_success       := LIGHT_THEME_SUCCESS
var theme_warning       := LIGHT_THEME_WARNING
var theme_error         := LIGHT_THEME_ERROR
var theme_accent        := LIGHT_THEME_ACCENT
var theme_font_color    := LIGHT_THEME_FONT_COLOR

var theme_preset := DEFAULT_THEME_PRESET
@onready var theme: Theme = preload("res://themes/theme.tres")


func get_settings(): # {{{
    return {
        "theme_preset"          : theme_preset,
        "theme_background"      : theme_background,
        "theme_complementary"   : theme_complementary,
        "theme_success"         : theme_success,
        "theme_warning"         : theme_warning,
        "theme_error"           : theme_error,
        "theme_accent"          : theme_accent,
        "theme_font_color"      : theme_font_color,
    }
# }}}

func reload_settings(): # {{{
    if theme_preset == ThemePresets.LIGHT:
        theme_background    = LIGHT_THEME_BACKGROUND
        theme_complementary = LIGHT_THEME_COMPLEMENTARY
        theme_success       = LIGHT_THEME_SUCCESS
        theme_warning       = LIGHT_THEME_WARNING
        theme_error         = LIGHT_THEME_ERROR
        theme_accent        = LIGHT_THEME_ACCENT
        theme_font_color    = LIGHT_THEME_FONT_COLOR

    if theme_preset == ThemePresets.DARK:
        theme_background    = Color.hex(0x323641ff)
        theme_complementary = Color.hex(0xa0a8b7ff)
        theme_success       = Color.hex(0x8ebd6bff)
        theme_warning       = Color.hex(0xe2b86bff)
        theme_error         = Color.hex(0xe55561ff)
        theme_accent        = Color.hex(0x48b0bdff)
        theme_font_color    = Color.hex(0xa0a8b7ff)

    for type in theme.get_type_list():
        for p_name in theme.get_stylebox_list(type):
            var s = theme.get_stylebox(p_name, type)
            if s is StyleBoxFlat:
                var bg_a = s.bg_color.a
                var border_a = s.border_color.a

                s.bg_color = theme_background if bg_a == 1 else theme_complementary

                if "focus" == p_name or "pressed" == p_name \
                        or "hover_focus" == p_name or "hover_pressed" == p_name:
                    s.border_color = theme_accent
                else:
                    s.border_color = theme_font_color

                s.bg_color.a = bg_a
                s.border_color.a = border_a
                theme.set_stylebox(p_name, type, s)

        for p_name in theme.get_color_list(type):
            if "font" in p_name or "caret" in p_name or "icon":
                var alp = theme.get_color(p_name, type).a
                var col = theme_font_color
                col.a = alp

                theme.set_color(p_name, type, col)

    # Fix edge cases
    # Code edit
    var a =  theme.get_color("background_color", "CodeEdit").a
    var c = theme_background

    c.a = a
    theme.set_color("background_color", "CodeEdit", c)

    a = theme.get_color("font_selected_color", "CodeEdit").a
    c.a = a
    theme.set_color("font_selected_color", "CodeEdit", c)

    a = theme.get_color("selection_color", "CodeEdit").a
    c = theme_font_color
    c.a = a
    theme.set_color("selection_color", "CodeEdit", c)

    a = theme.get_color("line_number_color", "CodeEdit").a
    c.a = a
    theme.set_color("line_number_color", "CodeEdit", c)

    # Link button
    c = Color.CORNFLOWER_BLUE
    theme.set_color("font_color", "LinkButton", c)

    c = Color.DARK_SLATE_BLUE
    theme.set_color("font_focus_color", "LinkButton", c)
    theme.set_color("font_hover_pressed_color", "LinkButton", c)

    c = Color.SLATE_BLUE
    theme.set_color("font_hover_color", "LinkButton", c)
    theme.set_color("font_pressed_color", "LinkButton", c)
# }}}

func get_default_setting(setting_name: String): # {{{
    match setting_name:
        "theme_preset"  : return DEFAULT_THEME_PRESET
        _               : return ERR_DOES_NOT_EXIST
# }}}
