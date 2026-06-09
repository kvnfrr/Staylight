extends Node2D

enum GameState { DRAWING, RUNNING, WON }

@onready var path_line: Line2D = $PathLine
@onready var spirit: Area2D = $Spirit
@onready var player: CharacterBody2D = $Player
@onready var message_label: Label = $UI/MessageLabel

var state := GameState.DRAWING
var path_points: Array[Vector2] = []
var min_point_distance := 8.0

var path_finished := false
var path_end_timer := 0.0
var path_end_grace_time := 3.0

var spirit_index := 0
var spirit_speed := 120.0

var safe_distance := 140.0
var uneasy_distance := 220.0
var danger_distance := 300.0

var danger_timer := 0.0
var danger_time_limit := 2.0
var was_in_danger := false

func _ready() -> void:
	player.controls_enabled = false

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
		if path_finished:
			update_path_end(delta)
		else:
			move_spirit(delta)
			update_danger(delta)

func add_path_point(pos: Vector2) -> void:
	if path_points.is_empty() or path_points[-1].distance_to(pos) >= min_point_distance:
		path_points.append(pos)
		path_line.add_point(pos)

func clear_path() -> void:
	path_points.clear()
	path_line.clear_points()
	message_label.text = "Draw the light's path."

func start_run() -> void:
	state = GameState.RUNNING
	spirit.global_position = path_points[0]
	spirit_index = 1
	player.controls_enabled = true
	danger_timer = 0.0
	was_in_danger = false
	message_label.text = "Follow the light."
	path_finished = false
	path_end_timer = 0.0

func move_spirit(delta: float) -> void:
	if spirit_index >= path_points.size():
		path_finished = true
		path_end_timer = 0.0
		message_label.text = "The light is fading..."
		return

	var target := path_points[spirit_index]
	spirit.global_position = spirit.global_position.move_toward(target, spirit_speed * delta)

	if spirit.global_position.distance_to(target) < 2.0:
		spirit_index += 1

func update_danger(delta: float) -> void:
	var distance := player.global_position.distance_to(spirit.global_position)

	if distance < safe_distance:
		danger_timer = 0.0

		if was_in_danger:
			message_label.text = "The sounds begin to fade..."
			was_in_danger = false
		else:
			message_label.text = ""

	elif distance < uneasy_distance:
		danger_timer = 0.0
		message_label.text = "You don't feel safe..."

	elif distance < danger_distance:
		danger_timer = 0.0
		was_in_danger = true
		message_label.text = "You hear something in the dark..."

	else:
		was_in_danger = true
		danger_timer += delta
		message_label.text = "Run."

		if danger_timer >= danger_time_limit:
			fail_run()

func fail_run() -> void:
	state = GameState.DRAWING
	player.controls_enabled = false
	spirit_index = 0
	danger_timer = 0.0
	was_in_danger = false
	message_label.text = "The dark found you. Press R to redraw."

func update_path_end(delta: float) -> void:
	path_end_timer += delta

	if path_end_timer >= path_end_grace_time:
		fail_run()


func _on_exit_body_entered(body: Node2D) -> void:
		if body == player and state == GameState.RUNNING:
			win_run()

func win_run() -> void:
	state = GameState.WON
	player.controls_enabled = false
	message_label.text = "You made it."
