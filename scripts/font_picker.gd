class_name FontPicker
extends Window


signal font_selected(font_name: String)

@onready var NotificationDialogScene = preload("res://scenes/notification_dialog.tscn")
@onready var font_button_cont = $Panel/Panel/ScrollContainer/FontButtonContainer
@onready var line_edit = $Panel/LineEdit

var fonts_directory := ""

## Alias for `LineEdit.text`
var selected_font := "":
    get: return line_edit.text
    set(val):
        line_edit.text = str(val)


func _ready() -> void: 
    close_requested.connect(_on_cancel_pressed)
    var os_name = OS.get_name().to_lower()

    match os_name:
        "linux", "bsd", "freebsd", "netbsd", "openbsd": fonts_directory = "/usr/share/fonts/"
        "windows": fonts_directory = "C:/Windows/Fonts/"
        "macos": fonts_directory = "/System/Library/Fonts/"

    var fonts = get_font_names(fonts_directory)
    create_font_buttons(fonts)


func get_font_names(fonts_dir: String) -> Array: 
    var dir = DirAccess.open(fonts_dir)
    if dir == null:
        var err  = DirAccess.get_open_error()
        printerr("Unable to get files at: '%s'" % fonts_dir)
        printerr("Error: '%s'" % err)

    var files = []
    for d in dir.get_directories():
        dir.change_dir(d)

        for f in dir.get_files():
            if not (".ttf" in f or ".otf" in f):
                continue
            files.append(f.get_basename().get_file())

        dir.change_dir("..")

    files.sort()
    return files


func create_font_buttons(fonts) -> void: 
    for c in font_button_cont.get_children():
        c.pressed.connect(_on_font_button_pressed.bind(c.text))
        c.gui_input.connect(_on_font_button_gui_input)

    for f in fonts:
        var b: Button = Button.new()
        font_button_cont.add_child(b)

        b.size_flags_horizontal = Control.SIZE_FILL
        b.size_flags_vertical = Control.SIZE_SHRINK_CENTER

        b.theme_type_variation = "FontButton"
        b.visible = true
        b.text = str(f)

        b.pressed.connect(_on_font_button_pressed.bind(b.text))
        b.gui_input.connect(_on_font_button_gui_input)



func _on_line_edit_text_changed(new_text: String) -> void: 
    new_text = new_text.strip_edges()
    for c in font_button_cont.get_children():
        c.visible = new_text in c.text || new_text.is_empty()


func _on_line_edit_text_submited(new_text: String) -> void: 
    new_text = new_text.to_lower()

    for c in font_button_cont.get_children():
        var font: String = c.text.to_lower()
        if "system default" in font:
            var v = font.split(" ")
            font = v[0]

        if font == new_text:
            selected_font = new_text
            _on_select_pressed()
            return

        var notif = NotificationDialogScene.instantiate()
        var msg = "Font '%s' not found"

        notif.type = NotificationDialog.NotificationType.ERROR
        notif.message = msg
        notif.duration = 5

        get_tree().root.get_node("Main").add_child(notif)


func _on_font_button_pressed(font_name: String) -> void: 
    if "System default" in font_name:
        var v = font_name.split(" ")
        font_name = v[0].to_lower()

    selected_font = font_name


func _on_font_button_gui_input(event: InputEvent): 
    if event is InputEventMouseButton and event.double_click:
        _on_line_edit_text_submited(selected_font)



func _on_cancel_pressed() -> void: 
    queue_free()


func _on_select_pressed() -> void: 
    font_selected.emit(selected_font)
    queue_free()

