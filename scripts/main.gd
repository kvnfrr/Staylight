extends Node2D

@onready var path_line: Line2D = $PathLine

var path_points: Array[Vector2] = []
var min_point_distance := 8.0
var can_draw := true

func _unhandled_input(event: InputEvent) -> void:
	if not can_draw:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			add_path_point(get_global_mouse_position())

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			add_path_point(get_global_mouse_position())

	if Input.is_action_just_pressed("clear_path"):
		clear_path()

func add_path_point(pos: Vector2) -> void:
	if path_points.is_empty() or path_points[-1].distance_to(pos) >= min_point_distance:
		path_points.append(pos)
		path_line.add_point(pos)

func clear_path() -> void:
	path_points.clear()
	path_line.clear_points()
