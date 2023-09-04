extends SubViewportContainer

@export var camera_path: NodePath

@onready var camera := get_node(camera_path) as Camera2D


func _ready() -> void:
	material = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA


func _on_ViewportContainer_mouse_entered() -> void:
	camera.set_process_input(true)
	Global.has_focus = true


func _on_ViewportContainer_mouse_exited() -> void:
	camera.set_process_input(false)
	Global.has_focus = false
