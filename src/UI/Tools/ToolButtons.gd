extends FlowContainer


func _input(event: InputEvent) -> void:
	if not Global.has_focus or not Global.can_draw:
		return
	if event is InputEventMouseMotion:
		return
	for action in ["undo", "redo"]:
		if event.is_action_pressed(action):
			return

	for tool_name in Tools.tools:  # Handle tool shortcuts
		if not get_node(tool_name).visible:
			continue
		var t: Tools.Tool = Tools.tools[tool_name]
		if InputMap.has_action("left_" + t.shortcut + "_tool"):
			if (
				event.is_action_pressed("left_" + t.shortcut + "_tool")
				and (!event.is_command_or_control_pressed())
			):
				# Shortcut for left button
				Tools.assign_tool(t.name, MOUSE_BUTTON_LEFT)
				return


func _on_Tool_pressed(tool_pressed: BaseButton) -> void:
	if Input.is_action_just_released("left_mouse"):
		Tools.assign_tool(tool_pressed.name, MOUSE_BUTTON_LEFT)
