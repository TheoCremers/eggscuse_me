extends Sprite

onready var green_eye = preload("res://assets/eye.sprites/eyeball_g.tres")
onready var red_eye = preload("res://assets/eye.sprites/eyeball.tres")

func _process(delta):
	var egg_direction = GameManager.egg.global_position - global_position
	rotation = -egg_direction.angle_to(Vector2.UP)

func _target_detected():
	texture = green_eye

func _target_lost():
	texture = red_eye
