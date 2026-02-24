extends CharacterBody2D

@export var fire_cooldown: float = 0.25
@export var bottle_scene: PackedScene
@export var walk_speed: float = 140.0
@export var run_speed: float = 240.0
@export var jump_velocity: float = -360.0
@export var gravity: float = 900.0
@export var health: int = 5
@export var enemy_scene: PackedScene 
@export var pixels_per_step: float = 40.0 
@export var steps_to_spawn: int = 15

@onready var anim: AnimatedSprite2D = $Anim
@onready var throw_point: Marker2D = $ThrowPoint

var _can_shoot := true
var facing_right := true
var total_distance_traveled: float = 0.0
var steps_taken: int = 0
var last_position: Vector2
var active_enemy: Node = null 

func _ready():
	last_position = global_position #

func _physics_process(delta):
	# --- Gravity ---
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if velocity.y > 0:
			velocity.y = 0

	# --- Input ---
	var input_dir := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

	# --- Speed & Movement ---
	var speed := walk_speed
	if Input.is_action_pressed("run"):
		speed = run_speed
	velocity.x = input_dir * speed

	# --- Facing Logic ---
	if input_dir != 0:
		facing_right = input_dir > 0
		anim.flip_h = not facing_right

	_update_throw_point()

	# --- Jump ---
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()
	_update_animation(input_dir)
	
	# --- Step Tracking ---
	if input_dir != 0 and is_on_floor():
		_track_movement()

	# --- Attack ---
	if Input.is_action_just_pressed("attack"):
		shoot()

func _update_animation(input_dir: float) -> void:
	if not is_on_floor():
		if anim.sprite_frames.has_animation("jump"):
			anim.play("jump")
		return

	if input_dir == 0:
		if anim.sprite_frames.has_animation("idle"):
			anim.play("idle")
		return

	if Input.is_action_pressed("run") and anim.sprite_frames.has_animation("run"):
		anim.play("run")
	elif anim.sprite_frames.has_animation("walk"):
		anim.play("walk")

func _update_throw_point() -> void:
	if facing_right:
		throw_point.position = Vector2(20, 0)
	else:
		throw_point.position = Vector2(-20, 0)

func shoot():
	if bottle_scene == null or not _can_shoot:
		return
		
	_can_shoot = false
	var b = bottle_scene.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = throw_point.global_position
	b.direction = Vector2.RIGHT if facing_right else Vector2.LEFT

	await get_tree().create_timer(fire_cooldown).timeout
	_can_shoot = true

func take_damage(amount: int):
	health -= amount
	print("Player Health: ", health)
	if health <= 0:
		# Use call_deferred to safely reload the scene after the physics frame
		get_tree().call_deferred("reload_current_scene")

func _track_movement():
	var distance_this_frame = global_position.distance_to(last_position)
	total_distance_traveled += distance_this_frame
	last_position = global_position

	if total_distance_traveled >= pixels_per_step:
		total_distance_traveled -= pixels_per_step
		steps_taken += 1
		print("Step count: ", steps_taken)
		
		if steps_taken >= steps_to_spawn:
			steps_taken = 0
			_check_and_spawn_enemy()

func _check_and_spawn_enemy():
	if is_instance_valid(active_enemy) and active_enemy.get_parent() != null:
		return
	
	if enemy_scene:
		active_enemy = enemy_scene.instantiate()
		var spawn_offset = Vector2(250, 0) if facing_right else Vector2(-250, 0)
		active_enemy.global_position = global_position + spawn_offset
		get_tree().current_scene.add_child(active_enemy)
		print("Shadow Self Spawned!")
