extends RigidBody2D

signal destroyed

var free = false
var velocity = Vector2.ZERO

var caught = false
var cracked = false
var s1   
var s2  
var high = 0
var iterator = 0 

onready var sound_crack = $CrackSound

func _integrate_forces(state):
	iterator += 1
	if iterator > 4:
		iterator = 0
	
	if iterator == 2:
		s1 = linear_velocity.length()
	if iterator == 0:
		s2 = linear_velocity.length()
		if s1 > s2:
			high = s1
		else:
			high = s2
		s1 = 0
		s2 = 0

# Called when the node enters the scene tree for the first time.
func _ready(): 
	contact_monitor = true
	contacts_reported = 10
	connect("body_entered", self, "on_body_entered")

func _physics_process(delta):
	if free:
		position += velocity * delta

func on_body_entered(body):
	#print(high)
	if high > 500 and not caught: egg_cracked()

func catch():
	caught = true
	yield(get_tree(), "idle_frame")
	caught = false

func egg_cracked():
	if not cracked:
		emit_signal("destroyed")
		$Sprite.texture = load("res://assets/egg_cracked.png")
		set_collision_layer_bit(2, false)
		set_collision_layer_bit(4, true)
		cracked = true
		# sound
		sound_crack.play()
		if not GameManager.ending:
			GameManager.restart_tip.visible = true

func yeet():
	mode = 3
	free = true
	# accelerate egg
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(self, "velocity", Vector2(0.0, -3500), Vector2.ZERO, 10)
	tween.start()

func reset(saved_position):
	mode = 3 # kinematic
	position = saved_position
	rotation = 0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	if cracked:
		cracked = false
		$Sprite.texture = load("res://assets/egg.png")
		set_collision_layer_bit(2, true)
		set_collision_layer_bit(4, false)
	yield(get_tree(), "idle_frame")
	mode = 0 # rigid

func hit_spikes():
	egg_cracked()
