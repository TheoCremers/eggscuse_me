extends Area2D

export(float) var break_time = 0.5
export(float) var break_mass = 1.0
var cracked = false

onready var damaged2_texture = preload("res://assets/cracks2.png")

onready var timer = $Timer
onready var cracks = $Cracks
onready var sound = $AudioStreamPlayer2D

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.set_wait_time(break_time)
	timer.one_shot = true
	timer.connect("timeout", self, "ground_break")
	timer.paused = true
	timer.start()


func _on_WeakFloor_body_entered(body):
	check_total_mass()


func _on_WeakFloor_body_exited(body):
	yield(get_tree(), "idle_frame")
	check_total_mass()

func check_total_mass():
	var total_mass = 0.0
	for overlap_body in get_overlapping_bodies():
		total_mass += overlap_body.mass
	if total_mass >= break_mass:
		if not cracks.visible:
			cracks.visible = true
			sound.play()
		timer.paused = false
	else:
		timer.paused = true

func ground_break():
	sound.play()
	if not cracked:
		cracks.texture = damaged2_texture
		cracked = true
		timer.start()
	else:
		visible = false
		$StaticBody2D.queue_free()
