extends Area2D

@export var speed: float = 520.0
@export var damage: int = 1
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT

func _ready():

	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	global_position += direction.normalized() * speed * delta

func _on_body_entered(body):
	print("BODY HIT:", body.name, body.get_class())
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	print("AREA HIT:", area.name, area.get_class())
	if area.has_method("take_damage"):
		area.take_damage(damage)
	queue_free()
