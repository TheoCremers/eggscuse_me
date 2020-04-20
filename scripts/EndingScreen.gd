extends Control

var ending_type = 0

onready var label1 = $DelayedLabel
onready var label2 = $DelayedLabel2
onready var label3 = $DelayedLabel3

func _ready():
	# carrying egg
	if ending_type == 1:
		if GameManager.egg.cracked:
			label2.text = "...was that crack always there?"
		else:
			label2.text = "...your Egg is safe forever."
	
	# only player
	if ending_type == 2:
		if GameManager.egg.free:
			label2.text = "...now where did that Egg go?"
		else:
			label2.text = "...didn't you forget something?"
	
	# carrying ???
	if ending_type == 3:
		label2.text = "The real reward is the friends we made along the way."
		label3.text = "Congratulations on finding the secret ending!"
	
	label1._on_signal()
	label2._on_signal()
	label3._on_signal()
