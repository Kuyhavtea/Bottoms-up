extends CharacterBody2D

# --- Variables ---
@export var max_health: int = 5
@export var attack_damage: int = 1
@export var speed: float = 80.0
@export var attack_range: float = 40.0 # How close he gets before hitting
@export var attack_cooldown: float = 3.0 # Your 3-second request

@onready var anim: AnimatedSprite2D = $Anim
@onready var player = get_tree().get_first_node_in_group("player") # Needs 'player' group!

var current_health: int
var gravity: float = 900.0
var is_dead: bool = false
var is_attacking: bool = false
var can_attack: bool = true

# --- Core Functions ---
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
		
		# ATTACK TRIGGER (No signal needed!)
		elif dist <= attack_range and can_attack:
			velocity.x = 0 # Stop to swing
			_start_attack()
	
	move_and_slide()
# --- Combat Logic ---
func _start_attack():
	if is_dead or is_attacking: return # Extra safety check
	
	is_attacking = true
	can_attack = false
	velocity.x = 0 # Freeze movement during the swing
	
	if anim.sprite_frames.has_animation("attack"):
		anim.play("attack")
		# We wait for the animation to reach the end
		await anim.animation_finished 
	
	# ONLY deal damage if the player is still close at the END of the swing
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < attack_range + 20:
			print("Damage dealt!")
			player.take_damage(attack_damage)

	# Reset movement state
	is_attacking = false 
	
	# Start the 3-second cooldown timer
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount: int):
	if is_dead: return
	
	current_health -= amount
	print("Shadow Hit! HP: ", current_health)
	
	# Flash effect for feedback
	modulate = Color(10, 1, 1) 
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if current_health <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO # Stop movement
	print("Shadow Self defeated!")
	
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished # Let the poof finish
	
	call_deferred("queue_free") # Safely delete
func _on_hitbox_area_entered(area: Area2D):
	#print("Area entered: ", area.name, " | Groups: ", area.get_groups())
	
	if area.is_in_group("player_attack"):
		print("HIT CONFIRMED on: ", area.name)
		take_damage(1)
		area.queue_free()

# 2. This handles the SHADOW hitting the PLAYER (Body)
func _on_hitbox_body_entered(body: Node2D):
	# We use 'body' here because a Player is a CharacterBody2D
	if body.name == "Player" and body.has_method("take_damage"):
		print("Enemy hit the Player!")
		body.take_damage(attack_damage)
