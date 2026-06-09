extends CharacterBody2D

@export var speed := 200.0
@export var jump_velocity := -350.0
@export var gravity := 1000.0

var controls_enabled := false

func _physics_process(delta: float) -> void:
	if not controls_enabled:
		velocity.x = 0

		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0

		move_and_slide()
		return

	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed

	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()
