extends Area2D

func _on_Spikes_body_entered(body):
	if body.has_method("hit_spikes"):
		body.call_deferred("hit_spikes")
