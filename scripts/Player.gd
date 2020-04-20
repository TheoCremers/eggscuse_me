extends KinematicBody2D

export(float) var move_speed = 230.0
export(float) var move_ground_accel = 25.0
export(float) var move_air_accel = 10.0
export(float) var move_ground_decel = 20.0
export(float) var move_damage_theshold = 990.0

export(float) var jump_speed = 535.0
export(float) var jump_decel = 20.0
export(float) var jump_buffer = 0.1 # seconds
export(float) var jump_hold_modifier = 0.82
export(float) var action_buffer = 0.1 # seconds

export(float) var up_gravity = 12.0
export(float) var down_gravity = 20.0
export(float) var terminal_speed = 1000.0

export(Vector2) var hold_offset = Vector2(0, -30.0)
export(Vector2) var drop_down_velocity = Vector2(0.0, 200.0)
export(Vector2) var drop_neutral_velocity = Vector2(500.0, -200.0)
export(Vector2) var drop_up_velocity = Vector2(200.0, -500.0)

var mass = 1.0

var velocity = Vector2.ZERO
var input_direction = 0.0
var facing_direction = 1

var jump_pressed = false
var try_jump = false
var do_action = false
var down_pressed = false
var up_pressed = false

var jump_controlled = false
var grounded = false
var holding = false
var holding_object = null
var alive = true
var crushed = false
var walking = false
var free = false

var prev_floor_velocity = Vector2.ZERO

onready var ground_detect = $GroundDetect
onready var pickup_detect = $PickupDetect
onready var debug_label = $"/root/Game/UI/DebugLabel"
onready var jump_buffer_timer = $JumpBuffer
onready var action_buffer_timer = $ActionBuffer
onready var holding_collider = $HoldingShape
onready var sprite = $Sprite
onready var stand_texture = preload("res://assets/player.sprites/player_stand.tres")
onready var hold_texture = preload("res://assets/player.sprites/player_hold.tres")

# Sounds
onready var sound_death = $DeathSound
onready var sound_jump = $JumpSound
onready var sound_pickup = $PickupSound
onready var sound_throw = $ThrowSound
onready var step_player = $StepSoundPlayer

func _ready():
	jump_buffer_timer.one_shot = true
	jump_buffer_timer.set_wait_time(jump_buffer)
	jump_buffer_timer.connect("timeout", self, "jump_buffer_timeout")
	
	action_buffer_timer.one_shot = true
	action_buffer_timer.set_wait_time(action_buffer)
	action_buffer_timer.connect("timeout", self, "action_buffer_timeout")
	
	holding_collider.position = hold_offset

func _physics_process(delta):
	if alive:
		get_input()
	
	if not free:
		calc_velocity()
	
	check_ground()
	
	# set facing direction
	if input_direction != 0:
		if facing_direction != input_direction:
			facing_direction = input_direction
			sprite.flip_h = !sprite.flip_h
	
	var pre_velocity = velocity
	velocity = move_and_slide(velocity, Vector2.UP, false, 4, PI/4.0, false)
	
	if holding: move_holding_object()
	
	check_walking()
	
	var floor_velocity = get_floor_velocity()
	if floor_velocity != prev_floor_velocity:
		velocity += prev_floor_velocity
		print(prev_floor_velocity)
	prev_floor_velocity = floor_velocity
	
	# check rapid deceleration (fall too hard)
#	if (velocity - pre_velocity).length() > move_damage_theshold:
#		on_death()
	
	if do_action and not free:
		try_action()
	
	update_debug()

func get_input():
	# input_directional input
	input_direction = 0.0
	if Input.is_action_pressed("right"):
		input_direction += 1.0
	if Input.is_action_pressed("left"):
		input_direction -= 1.0
	# jump input
	jump_pressed = Input.is_action_pressed("jump")
	if Input.is_action_just_pressed("jump"):
		try_jump = true
		jump_buffer_timer.start()
	# action input
	if Input.is_action_just_pressed("action"):
		do_action = true
		action_buffer_timer.start()
	# up/down input
	down_pressed = Input.is_action_pressed("down")
	up_pressed = Input.is_action_pressed("up")
	# eyes_close input
	if Input.is_action_just_pressed("close_eyes"):
		GameManager.close_eyes()
	if Input.is_action_just_released("close_eyes"):
		GameManager.open_eyes()

func check_ground():
	if ground_detect.get_overlapping_bodies():
		grounded = true
	else:
		grounded = false

func check_walking():
	if velocity.x * input_direction > 0 and grounded:
		if not walking:
			walking = true
			step_player.start_walking()
	else:
		if walking:
			walking = false
			step_player.stop_walking()

func calc_velocity():
	# move in input_direction
	if input_direction != 0 and input_direction * velocity.x <= move_speed:
		var accel = move_air_accel
		if grounded: accel = move_ground_accel
		if velocity.x * input_direction + accel < move_speed:
			velocity.x += accel * input_direction
		else: velocity.x = move_speed * input_direction
	# decelerate on the ground
	elif grounded and abs(velocity.x) > 0:
		if abs(velocity.x) - move_ground_decel < 0: velocity.x = 0
		else: velocity.x = velocity.x - sign(velocity.x) * move_ground_decel
	
	# vertical
	if try_jump and grounded:
		velocity.y = -jump_speed
		if holding: velocity.y *= jump_hold_modifier
		try_jump = false
		jump_controlled = true
		# sound
		sound_jump.play()
	# gravity
	var gravity_mod = down_gravity
	if velocity.y < terminal_speed:
		if velocity.y < 0:
			if jump_pressed or not jump_controlled:
				gravity_mod = up_gravity
			else:
				gravity_mod = up_gravity + jump_decel
		else: 
			jump_controlled = false
	velocity.y = clamp(velocity.y + gravity_mod, -100000000.0, terminal_speed)

func try_action():
	if holding:
		drop_object(true)
		do_action = false
		action_buffer_timer.stop()
	else:
		var closest_body = null
		var closest_distance_sq = 1000000000
		for body in pickup_detect.get_overlapping_bodies():
			if body.is_in_group("Holdable"):
				if (body.global_position - global_position).length_squared() < closest_distance_sq:
					closest_body = body
					closest_distance_sq = (body.global_position - global_position).length_squared()
		if closest_body != null:
			pickup_object(closest_body)
			do_action = false
			action_buffer_timer.stop()
			# sound
			sound_pickup.play()

func drop_object(thrown):
	# set drop velocity
	var drop_velocity = Vector2.ZERO
	var contributions = 0
	
	if thrown:
		if down_pressed:
			drop_velocity += drop_down_velocity
			contributions += 1
		if up_pressed:
			drop_velocity += drop_up_velocity
			contributions += 1
		if input_direction != 0:
			drop_velocity += drop_neutral_velocity
			contributions += 1
		if contributions > 0:
			drop_velocity.x *= facing_direction
			drop_velocity = drop_velocity / contributions
		drop_velocity += prev_floor_velocity
	else:
		drop_velocity = false
	
	reparent_to_world(holding_object, drop_velocity)
	
	if not holding_object.is_in_group("Egg"):
		reenable_collision(holding_object)
	
	# other stuff
	mass -= holding_object.mass
	holding_collider.disabled = true
	holding = false
	holding_object = null
	
	# TODO sprite
	sprite.texture = stand_texture
	if thrown and (up_pressed or input_direction != 0):
		# sound
		sound_throw.play()

func pickup_object(body):
	mass += body.mass
	#holding_collider.shape = body.get_node("CollisionShape2D").shape
	holding_collider.disabled = false
	holding = true
	holding_object = body
	# stop boxes from colliding with player when holding
	if holding_object.is_in_group("Egg"):
		holding_object.catch()
	else:
		holding_object.set_collision_layer_bit(1, false)
	yield(get_tree(), "idle_frame")
	reparent_to_player(body)
	# TODO sprite
	sprite.texture = hold_texture

func reparent_to_player(body):
	body.mode = 3 # kinematic
	#body.get_parent().remove_child(body)
	#add_child(body)
	#body.connect("destroyed", self, "on_holding_object_destroyed")
#	body.position = hold_offset
	move_holding_object()
	body.rotation = 0

func reparent_to_world(body, velocity):
	holding_object.mode = 0 # rigidbody
	var global_pos = body.get_global_position()
	#remove_child(body)
	#body.disconnect("destroyed", self, "on_holding_object_destroyed")
	#get_node("../").add_child(body)
	body.position = holding_object.get_parent().to_local(global_pos)
	if velocity:
		body.linear_velocity = velocity

func move_holding_object():
	holding_object.position = holding_object.get_parent().to_local(global_position + hold_offset)

func reenable_collision(body):
	# reenable box interaction with player
	# wait until box exits player body
	var inner_body = body.get_node("InnerBody")
	yield(inner_body, "body_exited")
	if holding_object != body:
		body.set_collision_layer_bit(1, true)

func update_debug():
	pass
#	debug_label.text = str("FPS: ", Performance.get_monitor(Performance.TIME_FPS), "\n",
#						   "velocity.x = ", velocity.x, "\n",
#						   "velocity.y = ", velocity.y, "\n",
#						   "grounded = ", grounded, "\n",
#						   "jump_pressed = ", jump_pressed, "\n",
#						   "jump_controlled = ", jump_controlled, "\n",
#						   "walking = ", walking, "\n",
#						   "eyes_closed = ", GameManager.eyes_closed, "\n")

func jump_buffer_timeout():
	try_jump = false

func action_buffer_timeout():
	do_action = false

func on_death():
	if holding:
		drop_object(false)
	# stop getting input
	alive = false
	input_direction = 0.0
	jump_pressed = false
	try_jump = false
	do_action = false
	down_pressed = false
	up_pressed = false
	# slowly close eyes
	GameManager.close_eyes(0.2)
	# look dead
	modulate = Color(0.5, 0.5, 0.5)
	# sound
	sound_death.play()
	GameManager.restart_tip.visible = true

func reset(saved_position):
	if holding:
		drop_object(false)
	velocity = Vector2.ZERO
	position = saved_position
	input_direction = 0.0
	jump_pressed = false
	try_jump = false
	do_action = false
	down_pressed = false
	up_pressed = false
	# hacky solution to fix dying on respawn when inside spikes
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	if not alive:
		alive = true
		modulate = Color(1.0, 1.0, 1.0)
		GameManager.open_eyes()
	# extra
	if free:
		free = false
		get_node("Tween").queue_free()

func yeet():
	# accelerate player
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(self, "velocity", Vector2(0.0, -3000), Vector2.ZERO, 10)
	tween.start()
	# manipulate camera
	var camera = get_node("Camera2D")
	camera.drag_margin_v_enabled = false
	camera.drag_margin_h_enabled = false
	var tween2 = Tween.new()
	add_child(tween2)
	tween2.interpolate_property(camera, "zoom", Vector2(1,1), Vector2(2,2), 10)
	tween2.start()
	free = true

func hit_spikes():
	if alive:
		on_death()

func on_holding_object_destroyed():
	holding = false
	holding_object = null


func _on_InnerBody_body_entered(body):
	call_deferred("on_death")
