# Totem.gd
extends StaticBody3D # Changed from Area3D

# Set this path to your Win Screen scene
@export var win_screen_scene_path: String = "res://Scenes/win_menu.tscn"

# Optional pickup sound node (if you add one as a child)
# @onready var pickup_sound = $PickupSound

# No _ready or _on_body_entered needed for interaction method

func interact():
	# This function is called by raycast.gd when the player interacts while looking at the totem

	print("Totem interacted! Triggering win screen.")

	# Optional: Play sound
	# if pickup_sound:
	#     pickup_sound.play()
	#     # Optional: Wait for sound to finish before changing scene
	#     # Note: This might feel unresponsive if the sound is long
	#     # await pickup_sound.finished

	# Immediately disable further interaction by disabling collision
	if $CollisionShape3D: # Check if CollisionShape3D exists
		$CollisionShape3D.disabled = true
	else:
		printerr("Totem Warning: Could not find CollisionShape3D to disable.")


	# Change to the Win Screen scene
	var error = get_tree().change_scene_to_file(win_screen_scene_path)
	if error != OK:
		printerr("Error changing scene to win screen: ", error)
		# Fallback?
		# get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

	# No queue_free needed as the scene change will unload this object.
