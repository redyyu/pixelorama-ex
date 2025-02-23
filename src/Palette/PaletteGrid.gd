class_name PaletteGrid
extends GridContainer

signal swatch_pressed(mouse_button, index)
signal swatch_double_clicked(mouse_button, index, position)
signal swatch_dropped(source_index, target_index)

const PALETTE_SWATCH_SCENE := preload("res://src/Palette/PaletteSwatch.tscn")
const DEFAULT_SWATCH_SIZE := Vector2(26, 26)
const MIN_SWATCH_SIZE := Vector2(8, 8)
const MAX_SWATCH_SIZE := Vector2(64, 64)

var swatches: Array[PaletteSwatch] = []
var current_palette: Palette = null
var grid_window_origin := Vector2.ZERO
var grid_size := Vector2.ZERO
var swatch_size := DEFAULT_SWATCH_SIZE


func _ready() -> void:
	swatch_size = Global.config_cache.get_value("palettes", "swatch_size", DEFAULT_SWATCH_SIZE)


func set_palette(new_palette: Palette) -> void:
	# Only display valid palette objects
	
	if not new_palette:
		return
	current_palette = new_palette
	grid_window_origin = Vector2.ZERO


func setup_swatches() -> void:
	# Columns cannot be 0
	columns = 1.0 if grid_size.x == 0.0 else grid_size.x
	if grid_size.x * grid_size.y > swatches.size():
		for i in range(swatches.size(), grid_size.x * grid_size.y):
			var swatch := PALETTE_SWATCH_SCENE.instantiate() as PaletteSwatch
			swatch.index = i
			init_swatch(swatch)
			swatch.pressed.connect(_on_PaletteSwatch_pressed.bind(i))
			swatch.double_clicked.connect(_on_PaletteSwatch_double_clicked.bind(i))
			swatch.dropped.connect(_on_PaletteSwatch_dropped)
			add_child(swatch)
			swatches.push_back(swatch)
	else:
		var diff := swatches.size() - grid_size.x * grid_size.y
		for _i in range(0, diff):
			var swatch: PaletteSwatch = swatches.pop_back()
			remove_child(swatch)
			swatch.queue_free()
		for i in range(0, swatches.size()):
			init_swatch(swatches[i])


func init_swatch(swatch: PaletteSwatch) -> void:
	swatch.color = PaletteSwatch.DEFAULT_COLOR
	swatch.current_selected_highlight = false
	swatch.empty = true
	swatch.set_swatch_size(swatch_size)


func draw_palette() -> void:
	for j in range(grid_size.y):
		for i in range(grid_size.x):
			var grid_index := i + grid_size.x * j
			var index := convert_grid_index_to_palette_index(grid_index)
			var swatch = swatches[grid_index]
			swatch.current_selected_highlight = false
			var color = current_palette.get_color(index)
			if color != null:
				swatch.color = color
				swatch.empty = false
			else:
				swatch.color = PaletteSwatch.DEFAULT_COLOR
				swatch.empty = true


func scroll_palette(origin: Vector2) -> void:
	grid_window_origin = origin
	draw_palette()


func find_and_select_color(mouse_button: int, target_color: Color) -> void:
	var old_index = Palettes.current_palette_get_selected_color_index(mouse_button)
	for color_ind in swatches.size():
		if target_color.is_equal_approx(swatches[color_ind].color):
			select_swatch(mouse_button, color_ind, old_index)
			match mouse_button:
				MOUSE_BUTTON_LEFT:
					Palettes.current_selected_color = color_ind
			break


## Displays a highlight over a swatch
func select_swatch(mouse_button: int, palette_index: int, old_palette_index: int) -> void:
	var index = convert_palette_index_to_grid_index(palette_index)
	var old_index = convert_palette_index_to_grid_index(old_palette_index)
	if index >= 0 and index < swatches.size():
		# Remove highlight from old index swatch and add to index swatch
		if old_index >= 0 and old_index < swatches.size():
			# Old index could be undefined when no swatch was previously selected
			swatches[old_index].show_selected(false)
		swatches[index].show_selected(true)
		print('current: ', swatches[index].current_selected_highlight if index >=0 else '')


func unselect_swatch(mouse_button: int, palette_index: int) -> void:
	var index = convert_palette_index_to_grid_index(palette_index)
	if index >= 0 and index < swatches.size():
		swatches[index].show_selected(false)


func set_swatch_color(palette_index: int, color: Color) -> void:
	var index = convert_palette_index_to_grid_index(palette_index)
	if index >= 0 and index < swatches.size():
		swatches[index].color = color


func get_swatch_color(palette_index: int) -> Color:
	var index = convert_palette_index_to_grid_index(palette_index)
	if index >= 0 and index < swatches.size():
		return swatches[index].color
	return Color.TRANSPARENT


## Used to reload empty swatch color from a theme
func reset_empty_swatches_color() -> void:
	for swatch in swatches:
		if swatch.empty:
			swatch.empty = true


## Grid index adds grid window origin
func convert_grid_index_to_palette_index(index: int) -> int:
	return (
		int(index / grid_size.x + grid_window_origin.y) * current_palette.width
		+ (index % int(grid_size.x) + grid_window_origin.x)
	)


func convert_palette_index_to_grid_index(palette_index: int) -> int:
	var x := palette_index % current_palette.width
	var y := palette_index / current_palette.width
	return int((x - grid_window_origin.x) + (y - grid_window_origin.y) * grid_size.x)


func resize_grid(new_rect_size: Vector2) -> void:
	if not is_instance_valid(current_palette):
		return
	var grid_x: int = (
		new_rect_size.x / (swatch_size.x + get("theme_override_constants/h_separation"))
	)
	var grid_y: int = (
		new_rect_size.y / (swatch_size.y + get("theme_override_constants/v_separation"))
	)
	grid_size.x = mini(grid_x, current_palette.width)
	grid_size.y = mini(grid_y, current_palette.height)
	setup_swatches()
	draw_palette()


func change_swatch_size(size_diff: Vector2) -> void:
	swatch_size += size_diff
	if swatch_size.x < MIN_SWATCH_SIZE.x:
		swatch_size = MIN_SWATCH_SIZE
	elif swatch_size.x > MAX_SWATCH_SIZE.x:
		swatch_size = MAX_SWATCH_SIZE

	for swatch in swatches:
		swatch.set_swatch_size(swatch_size)

	Global.config_cache.set_value("palettes", "swatch_size", swatch_size)


func _on_PaletteSwatch_pressed(mouse_button: int, index: int) -> void:
	var palette_index = convert_grid_index_to_palette_index(index)
	swatch_pressed.emit(mouse_button, palette_index)


func _on_PaletteSwatch_double_clicked(mouse_button: int, pos: Vector2, index: int) -> void:
	var palette_index = convert_grid_index_to_palette_index(index)
	swatch_double_clicked.emit(mouse_button, palette_index, pos)


func _on_PaletteSwatch_dropped(source_index: int, target_index: int) -> void:
	var palette_source_index := convert_grid_index_to_palette_index(source_index)
	var palette_target_index := convert_grid_index_to_palette_index(target_index)
	swatch_dropped.emit(palette_source_index, palette_target_index)
