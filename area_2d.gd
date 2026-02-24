extends Area2D

@export var speed: float = 520.0
@export var damage: int = 1
@export var lifetime: float = 2.0

# This will be set by the player/shooter when the projectile is spawned
var direction: Vector2 = Vector2.RIGHT

func _ready():
	# 1. Rotate the projectile to face the direction it's traveling
	rotation = direction.angle()
	
	# 2. Start the self-destruct timer
	await get_tree().create_timer(lifetime).timeout
	handle_destruction()

func _physics_process(delta: float):
	# Move the projectile in a straight line
	global_position += direction.normalized() * speed * delta

func _on_body_entered(body: Node2D):
	# Collision with physics objects (Tiles, Walls, StaticBodies)
	print("Hit Body: ", body.name)
	impact_logic(body)

func _on_area_entered(area: Area2D):
	# Collision with other Area2Ds (Hurtboxes, Items)
	print("Hit Area: ", area.name)
	impact_logic(area)

func impact_logic(target: Node):
	# 1. Check if the thing we hit (the Hitbox) has the script
	if target.has_method("take_damage"):
		target.take_damage(damage)
		handle_destruction()
		return

	# 2. Check the parent (The Enemy Root)
	var parent = target.get_parent()
	if parent and parent.has_method("take_damage"):
		parent.take_damage(damage)
		handle_destruction()
		return
	
	# 3. If it's just a wall or floor, still destroy the bottle
	if target is TileMap or target is StaticBody2D:
		handle_destruction()
func handle_destruction():
	# This removes the bottle from the game world
	queue_free() 
	# You can add "spawn_particles()" or "play_sound()" here later!
