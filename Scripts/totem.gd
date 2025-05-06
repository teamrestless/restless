extends RigidBody3D # Changed from Area3D

@export var win_screen_scene_path: String = "res://Scenes/win_menu.tscn"

# Optional pickup sound node (if you add one as a child)
# @onready var pickup_sound = $PickupSound

@onready var pickup_area = $PickupArea

func _ready():
	# Connect the body_entered signal from the CHILD Area3D node
	if pickup_area:
		pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	else:
		printerr("Totem Error: Cannot find child node 'PickupArea'!")

func _on_pickup_area_body_entered(body):
	# Check if the body that entered the PickupArea is the player
	if body.is_in_group("player"):
		print("Totem collected by player entering pickup area! Triggering win screen.")

		# Prevent the totem from moving or being detected further
		# Setting freeze prevents physics simulation
		freeze = true
		# Disabling the area prevents repeated signal triggers if needed
		if pickup_area:
			pickup_area.monitoring = false

		# Optional: Play pickup sound if you have one
		# if $PickupSound:
		#     $PickupSound.play()
		#     await $PickupSound.finished # Wait if needed
		
		call_deferred("change_scene_to_file", win_screen_scene_path)

		# Change to the Win Screen scene
		var error = get_tree().change_scene_to_file(win_screen_scene_path)
		if error != OK:
			printerr("Error changing scene to win screen: ", error)
			# Fallback?
			# get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

		# No need to queue_free usually, the scene change unloads the totem.

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
