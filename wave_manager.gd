extends Node2D

@export var enemy_scene: PackedScene
@onready var label = get_tree().current_scene.find_child("RichTextLabel")

# Wave Configuration
var current_wave: int = 0
var enemies_to_spawn: int = 0
var enemies_alive: int = 0
var spawn_interval: float = 3.0 # Increased to 3 seconds for slower spawning
var time_since_last_spawn: float = 0.0
var is_game_started: bool = false

func _ready():
	label.modulate.a = 1.0 

func start_game():
	is_game_started = true
	# Fade out the instructions quickly before starting Wave 1
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	await tween.finished
	start_next_wave()
	
func _process(delta):
	if not is_game_started:
		if Input.is_action_just_pressed("ui_accept"): 
			start_game()
			return
	if current_wave > 5: return

	# Handle slow spawning 1 by 1
	if enemies_to_spawn > 0:
		time_since_last_spawn += delta
		if time_since_last_spawn >= spawn_interval:
			spawn_enemy()
			time_since_last_spawn = 0.0

func start_next_wave():
	current_wave += 1
	
	# 1. Handle naming and color requirements
	var display_text = ""
	match current_wave:
		1: 
			enemies_to_spawn = 1
			display_text = "WAVE 1: SURVIVE"
		2: 
			enemies_to_spawn = 3
			display_text = "WAVE 2"
		3: 
			enemies_to_spawn = 5
			display_text = "WAVE 3"
		4: 
			enemies_to_spawn = 7
			display_text = "WAVE 4"
		5: 
			enemies_to_spawn = 10
			display_text = "FINAL BATTLE"
		6: 
			show_win()
			return

	update_objective_text(display_text)

func spawn_enemy():
	if enemy_scene == null: return
	
	var enemy = enemy_scene.instantiate()
	var spawn_side = 350 if randf() > 0.5 else -350
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		enemy.global_position = player.global_position + Vector2(spawn_side, -10)
		get_tree().current_scene.add_child(enemy)
		enemies_to_spawn -= 1
		enemies_alive += 1
		
		# Track when they die to proceed
		enemy.tree_exited.connect(_on_enemy_defeated)

func _on_enemy_defeated():
	enemies_alive -= 1
	
	# Safety check: If the player died and the tree is gone, stop here
	var tree = get_tree()
	if tree == null: return 
	
	if enemies_alive <= 0 and enemies_to_spawn <= 0:
		# Use the local 'tree' variable we just checked
		await tree.create_timer(2.0).timeout
		
		# One last check before starting the next wave
		if is_inside_tree():
			start_next_wave()

func update_objective_text(text_msg):
	if label:
		# Color changed to White [color=white]
		label.text = "[center][color=white]" + text_msg + "[/color][/center]"
		
		# Fade in/out logic
		label.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", 1.0, 1.0)
		await get_tree().create_timer(3.0).timeout
		var fade_out = create_tween()
		fade_out.tween_property(label, "modulate:a", 0.0, 1.0)

func show_win():
	if label:
		label.modulate.a = 1.0
		# Added [font_size=80] to make it significantly bigger
		label.text = "[center][color=green][font_size=80][b]YOU WIN[/b][/font_size][/color][/center]"
