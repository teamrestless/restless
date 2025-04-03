extends RayCast3D

var int_text

func _ready():
	int_text = get_node("/root/" + get_tree().current_scene.name + "/UI/interact_text")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_colliding():
		var hit = get_collider()
		if hit != null:
			if hit.has_method("interact"):
				int_text.visible = true
				if Input.is_action_just_pressed("interact"):
					hit.interact()
			else:
				int_text.visible = false
	else:
		int_text.visible = false
