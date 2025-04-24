extends StaticBody3D

var flashlight_energy
var energy_add_amount = 0.5
var pickup_sound
var flashlight

func _ready() -> void:
	flashlight = get_node("/root/" + get_tree().current_scene.name + "/Player/head/flashlight")
	flashlight_energy = get_node("/root/" + get_tree().current_scene.name + "/UI/flashlight_ui/flashlight_slider")
	pickup_sound = get_node("/root/" + get_tree().current_scene.name + "/Sounds/obj_pickup")

func interact():
	if flashlight.picked_up == true:
		flashlight_energy.value += energy_add_amount
		pickup_sound.play()
		queue_free()
