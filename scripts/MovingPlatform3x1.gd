extends StaticBody2D

export (bool) var connected = false
export (Vector2) var movement = Vector2(50.0, 0)
export (int) var max_increments = 100

var active = true
var increment = 0


func _ready():
	if connected:
		active = false

func _physics_process(delta):
	if active:
		if increment < max_increments:
			increment += 1
			position += movement * delta
			var object_movement = movement
			if object_movement.y > 0: object_movement.y = 0
			set_constant_linear_velocity(object_movement)
		else:
			set_constant_linear_velocity(Vector2.ZERO)
			if not connected:
				active = false
	else:
		if increment > 0:
			increment -= 1
			position -= movement * delta
			var object_movement = -movement
			if object_movement.y > 0: object_movement.y = 0
			set_constant_linear_velocity(object_movement)
		else:
			set_constant_linear_velocity(Vector2.ZERO)
			if not connected:
				active = true

func _on_positive_external_signal(arg1 = false):
	active = true

func _on_negative_external_signal(arg1 = false):
	active = false

