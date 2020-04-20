extends Node

signal eyes_closed
signal eyes_opening
signal eyes_closing

var eyes_closed = false
var eyes_closing = false

var saved_player_position
var saved_egg_position
var saved_scenes = []
var saved_scene_positions = []
var old_scenes = 1
var loading = false
var paused = false
var ending = false
var next_load_point = Vector2.ZERO

var upcoming_scenes = [preload("res://scenes/Zones/Zone2.tscn"),
					   preload("res://scenes/Zones/Zone3.tscn"),
					   preload("res://scenes/Zones/Zone4.tscn"),
					   preload("res://scenes/Zones/Zone5.tscn"),
					   preload("res://scenes/Zones/FinalZone.tscn")]
var transition_scene = preload("res://scenes/Zones/TransitionZone.tscn")
onready var world = $"/root/Game/World"
onready var egg = $"/root/Game/World/Egg"
onready var player = $"/root/Game/World/Player"
onready var eye_animation = $"/root/Game/Overlay/ColorRect/AnimationPlayer"
onready var restart_tip = $"/root/Game/Overlay/RestartLabel"
onready var pause_menu = $"/root/Game/Pause/PauseMenu"

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	saved_player_position = player.global_position
	saved_egg_position = egg.global_position
	for child in $"/root/Game/World".get_children():
		if child.is_in_group("Zones"):
			saved_scenes.append(child)
			saved_scene_positions.append(child.position)
	
	eye_animation.connect("animation_finished", self, "set_eyes_closed")
	VisualServer.set_default_clear_color(Color(0.0,0.0,0.0,1.0))

func _input(event):
	if event.is_action("restart") and !event.is_echo() and event.is_pressed():
		if not loading and not paused and not ending:
			player.reset(saved_player_position)
			egg.reset(saved_egg_position)
			reload_scenes()
			restart_tip.visible = false
	elif event.is_action("pause") and !event.is_echo() and event.is_pressed():
		if not ending:
			get_tree().paused = !get_tree().paused
			paused = get_tree().paused
			pause_menu.visible = paused

func close_eyes(anim_speed = 1.0):
	eye_animation.play("CloseEyes", -1, anim_speed)
	eyes_closing = true
	emit_signal("eyes_closing")

func open_eyes():
	eye_animation.play_backwards("CloseEyes")
	eyes_closing = false
	eyes_closed = false
	emit_signal("eyes_opening")

func set_eyes_closed(anim_name):
	eyes_closed = eyes_closing
	if eyes_closed:
		emit_signal("eyes_closed")

func load_next_zone(load_point):
	loading = true
	next_load_point = load_point
	call_deferred("update_world")

func update_world():
	# free old scenes
	for i in range(0, old_scenes):
		saved_scenes.pop_front().queue_free()
		saved_scene_positions.pop_front()
	old_scenes = 0
	
	var new_zone = upcoming_scenes.pop_front().instance()
	new_zone.position = next_load_point
	world.add_child(new_zone)
	# add to saved_zones
	saved_scenes.append(new_zone)
	saved_scene_positions.append(new_zone.position)
	old_scenes += 1
	
	# add transition zone
	if upcoming_scenes.size() > 0:
		var new_transition_zone = transition_scene.instance()
		new_transition_zone.position = new_zone.get_node("EndPoint").global_position
		world.add_child(new_transition_zone)
		# add to saved_zones
		saved_scenes.append(new_transition_zone)
		saved_scene_positions.append(new_transition_zone.position)
		old_scenes += 1
	
	saved_player_position = next_load_point + Vector2(-256, -32)
	saved_egg_position = next_load_point + Vector2(-128, -32)
	loading = false

func play_ending(type):
	restart_tip.visible = false
	if not ending:
		ending = true
		player.yeet()
		var ending_screen = load("res://scenes/EndingScreen.tscn").instance()
		ending_screen.ending_type = type
		get_node("/root/Game/Overlay").add_child(ending_screen)

func reload_scenes():
	for i in range(0, saved_scenes.size()):
		var a_root = saved_scenes[i]
		if not a_root:
			push_error("Root reference is not valid")
		if not a_root.filename:
			push_error("Root reference is not the root of any scene")
		var scene = load(a_root.filename)
		var parent = a_root.get_parent()
		if not parent:
			push_error("Root reference was not in the SceneTree")
		var index = a_root.get_index()
		a_root.free()
		saved_scenes[i] = scene.instance()
		saved_scenes[i].position = saved_scene_positions[i]
		parent.add_child(saved_scenes[i])
		parent.move_child(saved_scenes[i], index)
