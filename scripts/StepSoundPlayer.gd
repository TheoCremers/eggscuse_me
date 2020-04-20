extends Node2D

onready var timer = $Timer
onready var step_sounds = [$StepSound, $StepSound2, $StepSound3]
var rng = RandomNumberGenerator.new()
var step_interval = 0.3 # seconds
var step_sound_db = -10

func _ready():
	timer.set_wait_time(step_interval)
	timer.one_shot = false
	timer.connect("timeout", self, "play_random_step")
	
	for sound in step_sounds:
		sound.set_volume_db(step_sound_db)

func start_walking():
	play_random_step()
	timer.start()

func stop_walking():
	timer.stop()

func play_random_step():
	step_sounds[rng.randi() % 3].play()
