extends Area2D

onready var sound = $AudioStreamPlayer2D

func _on_Area2D_body_entered(body):
	sound.play()
	if body.is_in_group("Egg"):
		yield(get_tree(), "idle_frame")
		if not GameManager.ending:
			GameManager.egg.yeet()
	elif body.is_in_group("Player"):
		if body.holding:
			if body.holding_object.is_in_group("Egg"):
				GameManager.call_deferred("play_ending", 1)
			else:
				GameManager.call_deferred("play_ending", 3)
		else:
			GameManager.call_deferred("play_ending", 2)
