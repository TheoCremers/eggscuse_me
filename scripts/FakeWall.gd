extends Area2D

func _ready():
	$FakeTilemap.modulate.a = 1.0


func _on_FakeWall_body_entered(body):
	if body.is_in_group("Player"):
		$FakeTilemap.modulate.a = 0.5


func _on_FakeWall_body_exited(body):
	if body.is_in_group("Player"):
		$FakeTilemap.modulate.a = 1.0
