extends Label

export(float) var show_delay = 2.0

func _ready():
	modulate.a = 0

func _on_signal():
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(self, 'modulate:a', 0, 1, 1.0, 
	Tween.TRANS_LINEAR, Tween.EASE_IN, show_delay)
	tween.start()
	
