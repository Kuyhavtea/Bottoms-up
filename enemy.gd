extends CharacterBody2D

# --- Variables ---
@export var max_health: int = 5
@export var attack_damage: int = 1
@export var speed: float = 80.0
@export var attack_range: float = 40.0 
@export var attack_cooldown: float = 1.5 # Set to your requested 1.5s

@onready var anim: AnimatedSprite2D = $Anim
@onready var player = get_tree().get_first_node_in_group("player") 

var current_health: int
var gravity: float = 900.0
var is_dead: bool = false
var is_attacking: bool = false
var can_attack: bool = true

func _ready():
	current_health = max_health
	if anim.sprite_frames.has_animation("idle"):
		anim.play("idle")

func _physics_process(delta: float):
	if is_dead: return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if player:
		var dist = global_position.distance_to(player.global_position)
		
		# CHASE LOGIC
		if dist > attack_range and not is_attacking:
			var direction = (player.global_position - global_position).normalized()
			velocity.x = direction.x * speed
			anim.flip_h = direction.x < 0
			if anim.sprite_frames.has_animation("walk"):
				anim.play("walk")
		
		# ATTACK TRIGGER
		elif dist <= attack_range and can_attack:
			velocity.x = 0 
			_start_attack()
	
	move_and_slide()

# --- Combat Logic (Pro Fix) ---
func _start_attack():
	if is_dead or is_attacking: return
	
	is_attacking = true
	can_attack = false
	velocity.x = 0 
	
	if anim.sprite_frames.has_animation("attack"):
		anim.play("attack")
		
		# PRO FIX: Wait until the specific frame where the hit should land
		# Replace '2' with the actual frame number in your animation
		while anim.frame < 2:
			await get_tree().process_frame
		
		# DEAL DAMAGE IMMEDIATELY ON FRAME
		if is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if dist < attack_range + 20:
				print("Damage dealt on frame ", anim.frame)
				player.take_damage(attack_damage)
		
		# Wait for the rest of the animation to finish
		await anim.animation_finished 

	is_attacking = false
	
	# Start the 1.5s cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount: int):
	if is_dead: return
	current_health -= amount
	print("Shadow Hit! HP: ", current_health)
	
	modulate = Color(10, 1, 1) 
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if current_health <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	# Disable collisions so dead enemies don't block the player
	collision_layer = 0
	collision_mask = 0
	
	print("Shadow Self defeated!")
	
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished
	
	# This triggers the tree_exited signal in the WaveManager
	queue_free()


func _on_hitbox_area_entered(area: Area2D) -> void:
	# This checks if the thing that touched the enemy is the player's melee/bottle
	if area.is_in_group("player_attack"):
		print("Enemy detected hit from: ", area.name)
		take_damage(1) # Calls your existing damage function below
		
		# If it's a bottle, we want the bottle to disappear on hit
		if area.name.contains("Bottle"): 
			area.queue_free()
