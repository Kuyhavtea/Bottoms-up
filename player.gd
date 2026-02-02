extends CharacterBody2D

@export var fire_cooldown: float = 0.25
var _can_shoot := true
@export var bottle_scene: PackedScene
@export var walk_speed: float = 140.0
@export var run_speed: float = 240.0
@export var jump_velocity: float = -360.0
@export var gravity: float = 900.0

@onready var anim: AnimatedSprite2D = $Anim
@onready var throw_point: Marker2D = $ThrowPoint

var facing_right := true

func _physics_process(delta):
	# --- Gravity ---
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if velocity.y > 0:
			velocity.y = 0

	# --- Input ---
	var input_dir := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

	# --- Speed ---
	var speed := walk_speed
	if Input.is_action_pressed("run"):
		speed = run_speed
	velocity.x = input_dir * speed

	# --- Facing ---
	if input_dir != 0:
		facing_right = input_dir > 0
		anim.flip_h = not facing_right

	# ✅ Update throw point FIRST (so shoot uses correct side)
	_update_throw_point()

	# --- Jump ---
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

	_update_animation(input_dir)

	# ✅ Attack AFTER facing + throw point update
	if Input.is_action_just_pressed("attack"):
		shoot()


func _update_animation(input_dir: float) -> void:
	# If you don't have these animations yet, add them or rename below.
	if not is_on_floor():
		if anim.sprite_frames.has_animation("jump"):
			anim.play("jump")
		return

	if input_dir == 0:
		if anim.sprite_frames.has_animation("idle"):
			anim.play("idle")
		return

	# Moving on ground
	if Input.is_action_pressed("run") and anim.sprite_frames.has_animation("run"):
		anim.play("run")
	elif anim.sprite_frames.has_animation("walk"):
		anim.play("walk")
	else:
		# fallback if you only have "run"
		if anim.sprite_frames.has_animation("run"):
			anim.play("run")

func _update_throw_point() -> void:
	throw_point.position = Vector2(15, -4) if facing_right else Vector2(-15, -4)
	
func shoot():
	if bottle_scene == null or not _can_shoot:
		return

	_can_shoot = false

	var b = bottle_scene.instantiate()

	# Facing based on what you SEE
	var dir := Vector2.RIGHT
	if anim.flip_h:
		dir = Vector2.LEFT

	# Spawn from player's hand area (world coords)
	var spawn_offset := Vector2(24, -8)
	spawn_offset.x *= dir.x  # flips offset left/right

	# Add first, then position (prevents reset bugs)
	get_tree().current_scene.add_child(b)
	b.global_position = global_position + spawn_offset
	b.direction = dir

	print("flip_h:", anim.flip_h, " dir:", dir, " spawn:", b.global_position, " player:", global_position)

	await get_tree().create_timer(fire_cooldown).timeout
	_can_shoot = true
