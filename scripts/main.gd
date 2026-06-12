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

var player_spawn_position: Vector2
var spirit_spawn_position: Vector2

var spirit_index := 0
var spirit_speed := 120.0

var safe_distance := 140.0
var uneasy_distance := 220.0
var danger_distance := 300.0

var danger_timer := 0.0
var danger_time_limit := 2.0
var was_in_danger := false

var is_drawing_path := false
var spirit_start_radius := 24.0

var max_path_length := 700.0
var current_path_length := 0.0

func _ready() -> void:
	set_spawn_positions_from_level()
	connect_level_signals()

	player.global_position = player_spawn_position
	spirit.global_position = spirit_spawn_position

	player.controls_enabled = false
	message_label.text = "Draw the light's path."

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("clear_path"):
		reset_run()
		return

	if state != GameState.DRAWING:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse_pos := get_global_mouse_position()

			if mouse_pos.distance_to(spirit.global_position) <= spirit_start_radius:
				begin_new_path()
		else:
			is_drawing_path = false

	if event is InputEventMouseMotion and is_drawing_path:
		add_path_point(get_global_mouse_position())

	if Input.is_action_just_pressed("start_run") and path_points.size() > 1:
		is_drawing_path = false
		start_run()

func _process(delta: float) -> void:
	if state == GameState.RUNNING:
		if path_finished:
			update_path_end(delta)
		else:
			move_spirit(delta)
			update_danger(delta)

func add_path_point(pos: Vector2) -> void:
	if path_points.is_empty():
		path_points.append(pos)
		path_line.add_point(pos)
		return

	var last_point := path_points[-1]
	var segment_length := last_point.distance_to(pos)

	if segment_length < min_point_distance:
		return

	if current_path_length + segment_length > max_path_length:
		is_drawing_path = false
		message_label.text = "The light cannot stretch further."
		return

	current_path_length += segment_length
	path_points.append(pos)
	path_line.add_point(pos)

	message_label.text = "Light remaining: %s%%" % get_light_remaining_percent()

func begin_new_path() -> void:
	path_points.clear()
	path_line.clear_points()

	current_path_length = 0.0
	is_drawing_path = true

	add_path_point(spirit.global_position)
	message_label.text = "Light remaining: 100%"

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

func fail_run(message := "The dark found you. Press R to retry.") -> void:
	state = GameState.DRAWING
	player.controls_enabled = false
	spirit_index = 0
	danger_timer = 0.0
	was_in_danger = false
	path_finished = false
	path_end_timer = 0.0
	message_label.text = message

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

func reset_run() -> void:
	state = GameState.DRAWING

	player.global_position = player_spawn_position
	player.velocity = Vector2.ZERO
	player.controls_enabled = false

	spirit.global_position = spirit_spawn_position
	spirit_index = 0

	path_points.clear()
	path_line.clear_points()

	danger_timer = 0.0
	was_in_danger = false
	path_finished = false
	path_end_timer = 0.0

	message_label.text = "Draw the light's path."
	
	current_path_length = 0.0
	is_drawing_path = false
	
	player.global_position = player_spawn_position
	spirit.global_position = spirit_spawn_position

func _on_death_zone_body_entered(body: Node2D) -> void:
	if body == player and state == GameState.RUNNING:
		fail_run("You fell. Press R to retry.")

func get_light_remaining_percent() -> int:
	var remaining := 1.0 - (current_path_length / max_path_length)
	remaining = clamp(remaining, 0.0, 1.0)
	return int(round(remaining * 100.0))

func set_spawn_positions_from_level() -> void:
	var player_spawn := $World.get_node("PlayerSpawn")
	var spirit_spawn := $World.get_node("SpiritSpawn")

	player_spawn_position = player_spawn.global_position
	spirit_spawn_position = spirit_spawn.global_position
	connect_level_signals()

func connect_level_signals() -> void:
	var exit := $World.get_node("Exit")
	var death_zone := $World.get_node("DeathZone")

	if not exit.body_entered.is_connected(_on_exit_body_entered):
		exit.body_entered.connect(_on_exit_body_entered)

	if not death_zone.body_entered.is_connected(_on_death_zone_body_entered):
		death_zone.body_entered.connect(_on_death_zone_body_entered)
