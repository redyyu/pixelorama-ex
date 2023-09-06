class_name PaletteSwatch
extends ColorRect

signal pressed(mouse_button)
signal double_clicked(mouse_button, position)
signal dropped(source_index, new_index)

const DEFAULT_COLOR := Color(0.0, 0.0, 0.0, 0.0)

var index := -1
var current_selected_highlight := false
var empty := true:
	set(value):
		empty = value
		if empty:
			mouse_default_cursor_shape = Control.CURSOR_ARROW
			color = Global.control.theme.get_stylebox("disabled", "Button").bg_color
		else:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func set_swatch_size(swatch_size: Vector2) -> void:
	custom_minimum_size = swatch_size
	size = swatch_size


func _draw() -> void:
	if current_selected_highlight:
		# Display outer border highlight
		draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE, false, 1)


## Enables drawing of highlights which indicate selected swatches
func show_selected(new_value: bool) -> void:
	if not empty:
		current_selected_highlight = new_value
	queue_redraw()


func _get_drag_data(_position: Vector2):
	var data = null
	if not empty:
		var drag_icon: PaletteSwatch = self.duplicate()
		drag_icon.current_selected_highlight = false
		drag_icon.empty = false
		set_drag_preview(drag_icon)
		data = {source_index = index}
	return data


func _can_drop_data(_position: Vector2, _data) -> bool:
	return true


func _drop_data(_position: Vector2, data) -> void:
	dropped.emit(data.source_index, index)


func _on_PaletteSlot_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and not empty:
		if event.double_click:
			double_clicked.emit(event.button_index, get_global_rect().position)
		else:
			pressed.emit(event.button_index)
