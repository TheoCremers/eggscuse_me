extends Area2D

export(Vector2) var acceleration = Vector2(2000.0, 0)
var player_multiplier = 1.2
onready var sound = $AudioStreamPlayer2D

func _on_Area2D_body_entered(body):
	sound.play()
	if body.is_in_group("Holdable"):
		if body.mode == 0:
			body.linear_velocity = acceleration.rotated(rotation)
	elif body.is_in_group("Player"):
		body.velocity = acceleration.rotated(rotation) * player_multiplier
		body.jump_controlled = false
