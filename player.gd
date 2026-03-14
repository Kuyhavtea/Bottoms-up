extends CharacterBody2D

# --- Variables ---
@export var fire_cooldown: float = 0.25
@export var bottle_scene: PackedScene
@export var walk_speed: float = 140.0
@export var run_speed: float = 240.0
@export var jump_velocity: float = -360.0
@export var gravity: float = 900.0
@export var health: int = 10
@export var enemy_scene: PackedScene 

@onready var anim: AnimatedSprite2D = $Anim
@onready var throw_point: Marker2D = $ThrowPoint

# --- Weapon & Melee ---
enum WeaponMode { PROJECTILE, MELEE }
var current_weapon_mode: WeaponMode = WeaponMode.PROJECTILE
@onready var melee_area = $MeleeArea
@onready var melee_shape = $MeleeArea/CollisionShape2D

# --- State & Tracking ---
var is_dead: bool = false 
var is_meleeing: bool = false
var attack_count: int = 0 # 0 for melee_1, 1 for melee_2
var _can_shoot := true
var facing_right := true



func _ready():
	if melee_shape:
		melee_shape.disabled = true

func _physics_process(delta):
	if is_dead: return

	# --- 1. Weapon Switching (R Key) ---
	if Input.is_action_just_pressed("switch_weapon"): 
		_toggle_weapon_mode()

	# --- 2. Gravity ---
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if velocity.y > 0:
			velocity.y = 0

	# --- 3. Horizontal Movement ---
	var input_dir := Input.get_axis("move_left", "move_right") # Cleaner input
	var speed := run_speed if Input.is_action_pressed("run") else walk_speed
	
	# Allowing movement during melee as requested
	velocity.x = input_dir * speed

	# --- 4. Facing Logic ---
	if input_dir != 0:
		facing_right = input_dir > 0
		anim.flip_h = not facing_right
		
		# Cancel melee if we move
		if is_meleeing:
			_cancel_attack()
	
	_update_offsets()

	# --- 5. Jump ---
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# --- 6. Combat Input (J Key) ---
	if Input.is_action_just_pressed("attack"):
		if current_weapon_mode == WeaponMode.MELEE:
			melee_attack()
		else:
			shoot()

	move_and_slide()
	_update_animation(input_dir)
	


# --- Logic Functions ---

func _toggle_weapon_mode():
	if current_weapon_mode == WeaponMode.PROJECTILE:
		current_weapon_mode = WeaponMode.MELEE
	else:
		current_weapon_mode = WeaponMode.PROJECTILE
	print("Stance: ", current_weapon_mode)

func _update_animation(input_dir: float) -> void:
	if not is_on_floor():
		_play_if_new("jump")
		return

	if is_meleeing: return # Don't overwrite attack animations

	if input_dir == 0:
		if current_weapon_mode == WeaponMode.MELEE and anim.sprite_frames.has_animation("melee_idle"):
			_play_if_new("melee_idle")
		else:
			_play_if_new("idle")
		return

	if Input.is_action_pressed("run") and anim.sprite_frames.has_animation("run"):
		_play_if_new("run")
	else:
		_play_if_new("walk")

func _play_if_new(anim_name: String):
	if anim.animation != anim_name:
		anim.play(anim_name)

func _update_offsets() -> void:
	var x_offset = 15 if facing_right else -15 # Adjusted for smaller sprite
	throw_point.position.x = x_offset
	if melee_area:
		melee_area.position.x = x_offset

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
func melee_attack():
	if is_meleeing: return
	is_meleeing = true
	
	var damage_has_dealt = false # 🛡️ This prevents the "shotgun" effect
	
	if anim.sprite_frames.has_animation("melee"):
		anim.play("melee")
		
		while anim.frame < 2:
			if Input.get_axis("move_left", "move_right") != 0:
				_cancel_attack()
				return
			await get_tree().process_frame

		# Only deal damage if we haven't already hit this swing
		if not damage_has_dealt:
			melee_shape.disabled = false
			print("--- Melee Impact ---")
			
			# Wait a tiny bit for the physics engine to catch the collision
			await get_tree().create_timer(0.05).timeout 
			
			melee_shape.disabled = true
			damage_has_dealt = true # 🛑 Block further hits until next 'J' press
		
		await anim.animation_finished
	
	is_meleeing = false

func _cancel_attack():
	is_meleeing = false
	melee_shape.disabled = true
	anim.stop() # Immediately stop the swinging animation
	print("Attack Canceled by Movement")

func take_damage(amount: int):
	if is_dead: return
	health -= amount
	if health <= 0:
		die()
	else:
		modulate = Color(10, 1, 1)
		await get_tree().create_timer(0.1).timeout
		modulate = Color(1, 1, 1)

func die():
	if is_dead: return # 🛑 Prevents the function from running twice
	is_dead = true
	velocity = Vector2.ZERO
	
	# Store the tree reference immediately so it doesn't become null later
	var game_tree = get_tree()
	
	# Show Game Over Text
	var label = game_tree.current_scene.find_child("RichTextLabel")
	if label:
		label.modulate.a = 1.0
		label.text = "[center][color=red][font_size=70]GAME OVER[/font_size][/color][/center]"
	
	# Play death animation
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished
	
	# Wait for 5 seconds using our saved reference
	if game_tree:
		await game_tree.create_timer(5.0).timeout
		game_tree.reload_current_scene()
