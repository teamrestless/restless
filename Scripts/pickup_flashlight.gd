# pickup_flashlight.gd
extends StaticBody3D

var player_script

@onready var pickup_sound = get_node("/root/" + get_tree().current_scene.name + "/Sounds/obj_pickup")

func _ready() -> void:
	player_script = get_node("/root/" + get_tree().current_scene.name + "/Player")
	if player_script == null:
		print("Error in pickup_flashlight: Could not find Player node.")
	if pickup_sound == null:
		print("Warning in pickup_flashlight: Could not find pickup_sound node.")

func interact():
	if player_script != null:
		# --- CHANGE THIS LINE ---
		# Call the new function to mark the flashlight as obtained (initially empty)
		if player_script.has_method("obtain_flashlight"):
			player_script.obtain_flashlight()
		else:
			print("Error in pickup_flashlight: Player script does not have obtain_flashlight method.")
		# --- END CHANGE ---

		if pickup_sound != null:
			pickup_sound.play()
		else:
			print("Warning in pickup_flashlight: pickup_sound node not found, skipping sound.")

		queue_free()
	else:
		print("Error in pickup_flashlight: Cannot interact, player_script reference is null.")
