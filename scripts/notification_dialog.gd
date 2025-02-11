class_name NotificationDialog
extends Button


@onready var progress_bar = $ProgressBar
@onready var timer = $Timer

enum NotificationType {
    NORMAL,
    WARNING,
    ERROR,
    SUCCESS,
}

## Alias for `text`
var message: String = "":
    get: return text
    set(msg): text = str(msg)

var duration := 1.0
var type := NotificationType.NORMAL


func _ready() -> void: 
    progress_bar.max_value = duration
    timer.wait_time = duration

    $AnimationPlayer.play("open")
    timer.start()
    show()

    var app_theme: AppTheme = get_tree().root.get_node("Main/Settings/AppTheme")
    var color
    match type:
        NotificationType.NORMAL: color = app_theme.theme_accent
        NotificationType.WARNING: color = app_theme.theme_warning
        NotificationType.ERROR: color = app_theme.theme_error
        NotificationType.SUCCESS: color = app_theme.theme_success
            
 
    var style: StyleBoxFlat = get_theme_stylebox("normal")
    style.border_color = color
    add_theme_stylebox_override("normal", style)

    style = get_theme_stylebox("hover")
    style.border_color = color
    add_theme_stylebox_override("hover", style)

    style = progress_bar.get_theme_stylebox("fill")
    color.a = style.bg_color.a
    style.bg_color = color


func _process(_delta: float) -> void:
    if !timer.is_stopped():
        progress_bar.value = timer.wait_time - timer.time_left


func _on_pressed() -> void:
    timer.stop()
    progress_bar.value = progress_bar.max_value
    $AnimationPlayer.play("close")


func _on_timer_timeout() -> void:
    $AnimationPlayer.play("close")

