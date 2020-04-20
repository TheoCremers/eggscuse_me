extends AnimatedSprite

signal detected
signal lost

export(int, "player", "egg", "both") var target = 0
var target_objects
var current_targets_detected = 0

onready var green_eye = preload("res://assets/eye.sprites/eyeball_g.tres")
onready var red_eye = preload("res://assets/eye.sprites/eyeball.tres")
onready var eyeball = $EyeBall
onready var detection = $DetectionArea

onready var on_sound = $OnSound
onready var off_sound = $OffSound

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.connect("eyes_closing", self, "close_eye")
	GameManager.connect("eyes_opening", self, "open_eye")
	GameManager.connect("eyes_closed", self, "stop_detecting")
	# set target
	if target == 0:
		target_objects = [GameManager.player]
		detection.set_collision_mask_bit(0, true)
	elif target == 1:
		target_objects = [GameManager.egg]
		detection.set_collision_mask_bit(2, true)
	elif target == 2:
		target_objects =  [GameManager.player, GameManager.egg]
		detection.set_collision_mask_bit(2, true)
		detection.set_collision_mask_bit(0, true)
	
func _process(delta):
	var target_direction = Vector2.UP * 10000000
	for object in target_objects:
		var new_target_direction = object.global_position - global_position
		if target_direction.length_squared() > new_target_direction.length_squared():
			target_direction = new_target_direction
	eyeball.rotation = -target_direction.angle_to(Vector2.UP)

func _target_detected(body):
	current_targets_detected += 1
	if target < 2 or current_targets_detected >= 2:
		eyeball.texture = green_eye
		emit_signal("detected")
		on_sound.play()

func _target_lost(body):
	current_targets_detected -= 1
	eyeball.texture = red_eye
	emit_signal("lost")
	off_sound.play()

func close_eye():
	play()

func open_eye():
	play("", true)
	detection.get_node("CollisionShape2D").set_deferred("disabled", false)

func stop_detecting():
	detection.get_node("CollisionShape2D").set_deferred("disabled", true)
