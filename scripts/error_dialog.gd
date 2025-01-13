class_name ErrorDialog
extends AcceptDialog


const BUG_REPORT_URI := "https://github.com"
var report_bug := true


func _ready() -> void:
    # {{{
    title = "Error!"
    ok_button_text = "Close"
    show()
    if report_bug:
        custom_action.connect(_on_custom_action)
        add_button("Report bug", false, 'report_bug')

    for c in get_children(true):
        if c is Panel: c.remove_theme_stylebox_override("panel")
        if c is Label: c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
# }}}

## Add more info to the error code
##
## Only works on more common errors
static func expand_error_code(code: Error) -> String:
    # {{{
    var msg = str(code)
    match code:
        ERR_FILE_NOT_FOUND:         msg += ", File not found"
        ERR_FILE_NO_PERMISSION:     msg += ", File doesn't have permission"
        ERR_FILE_ALREADY_IN_USE:    msg += ", File is already in use"
        ERR_FILE_CANT_OPEN:         msg += ", Unable to open file"
        ERR_FILE_CANT_WRITE:        msg += ", Unable to write file"
        ERR_FILE_CANT_READ:         msg += ", Unable to read file"
        ERR_FILE_UNRECOGNIZED:      msg += ", Unable to recognize file"
        ERR_FILE_CORRUPT:           msg += ", File is corrupt"

    return msg
# }}}

func _on_custom_action(action: String) -> void:
    # {{{
    if action != "report_bug":
        return

    OS.shell_open(BUG_REPORT_URI)
# }}}
