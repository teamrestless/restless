extends Area3D

@export var monster: CharacterBody3D

func spawn_monster(body):
	if body == get_node("/root/" + get_tree().current_scene.name + "/Player"):
		monster.visible = true

func _on_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
