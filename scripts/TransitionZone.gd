extends Node2D

func _ready():
	$EvilEye2.connect("detected", GameManager, "load_next_zone", [$LoadPoint.global_position], CONNECT_ONESHOT)
