extends Node2D

enum GameState { DRAWING, RUNNING }

@onready var path_line: Line2D = $PathLine
@onready var spirit: Area2D = $Spirit

var state := GameState.DRAWING
var path_points: Array[Vector2] = []
var min_point_distance := 8.0

var spirit_index := 0
var spirit_speed := 120.0

func _unhandled_input(event: InputEvent) -> void:
	if state != GameState.DRAWING:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			add_path_point(get_global_mouse_position())

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			add_path_point(get_global_mouse_position())

	if Input.is_action_just_pressed("clear_path"):
		clear_path()

	if Input.is_action_just_pressed("start_run") and path_points.size() > 1:
		start_run()

func _process(delta: float) -> void:
	if state == GameState.RUNNING:
		move_spirit(delta)

func add_path_point(pos: Vector2) -> void:
	if path_points.is_empty() or path_points[-1].distance_to(pos) >= min_point_distance:
		path_points.append(pos)
		path_line.add_point(pos)

func clear_path() -> void:
	path_points.clear()
	path_line.clear_points()

func start_run() -> void:
	state = GameState.RUNNING
	spirit.global_position = path_points[0]
	spirit_index = 1

func move_spirit(delta: float) -> void:
	if spirit_index >= path_points.size():
		state = GameState.DRAWING
		return

	var target := path_points[spirit_index]
	spirit.global_position = spirit.global_position.move_toward(target, spirit_speed * delta)

	if spirit.global_position.distance_to(target) < 2.0:
		spirit_index += 1
