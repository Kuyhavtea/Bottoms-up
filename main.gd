extends Node2D
@onready var objective_text = $CanvasLayer/RichTextLabel

func _ready():
	# 1. Start completely invisible (Alpha = 0)
	objective_text.modulate.a = 0
	
	# 2. Call the fade sequence
	fade_objective()

func fade_objective():
	var tween = create_tween()
	
	# FADE IN: Change opacity (a) to 1 over 1.5 seconds
	tween.tween_property(objective_text, "modulate:a", 1.0, 1.5)
	
	# DELAY: Keep it visible for 2 seconds
	tween.tween_interval(2.0)
	
	# FADE OUT: Change opacity back to 0 over 1.5 seconds
	tween.tween_property(objective_text, "modulate:a", 0.0, 1.5)
