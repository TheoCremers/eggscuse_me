extends Area2D

signal pressed
signal stop_pressed

var pressed = false
var occupants = []
var press_speed = 0.5
var min_y = 6.0
var max_y = 12.0

onready var plate = $StaticBody2D

func _ready():
	pass

func _physics_process(delta):
	if occupants:
		if plate.position.y < max_y:
			plate.position.y += press_speed
			for body in occupants:
				body.position.y += press_speed
		else:
			if not pressed:
				pressed = true
				emit_signal("pressed")
	elif plate.position.y > min_y:
		plate.position.y -= press_speed
		if pressed:
			pressed = false
			emit_signal("stop_pressed")


func _on_PressurePlate_body_entered(body):
	occupants.append(body)


func _on_PressurePlate_body_exited(body):
	occupants.erase(body)
