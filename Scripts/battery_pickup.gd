# BatteryPickup.gd
extends StaticBody3D

signal picked_up

func interact():
	print("BatteryPickup: interact() function called.") # DEBUG

	var player = get_node("/root/" + get_tree().current_scene.name + "/Player")

	if player == null:
		printerr("BatteryPickup Error: Could not find Player node.")
		return

	if not player.has_method("gain_flashlight_charge") or not "has_obtained_flashlight" in player or not "has_flashlight_charge" in player:
		printerr("BatteryPickup Error: Player node is missing required members.")
		return

	print("  - Checking player.has_obtained_flashlight: ", player.has_obtained_flashlight) # DEBUG
	if not player.has_obtained_flashlight:
		print("  - Interaction blocked: Flashlight not obtained.") # DEBUG
		# Optionally play a specific sound here indicating you can't interact yet
		# e.g., $CannotInteractSound.play()
		return # --- Primary block ---

	print("  - Checking player.has_flashlight_charge: ", player.has_flashlight_charge) # DEBUG
	if player.has_flashlight_charge:
		print("  - Interaction blocked: Player already has charge.") # DEBUG
		# Optionally play a different sound for "already full"
		return # --- Secondary block ---

	# --- If checks pass ---
	print("  - Interaction SUCCESSFUL!") # DEBUG
	player.gain_flashlight_charge()

	var pickup_sound_node = get_node_or_null("/root/" + get_tree().current_scene.name + "/Sounds/obj_pickup") # Check this path
	if pickup_sound_node != null:
		pickup_sound_node.play()
	else:
		print("BatteryPickup Warning: Pickup sound node not found.")

	emit_signal("picked_up")
	queue_free()
