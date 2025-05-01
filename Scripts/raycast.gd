# raycast.gd
extends RayCast3D

# Make sure this path is correct for your BatteryPickup script!
const BatteryPickupScript = preload("res://Scripts/battery_pickup.gd") # Or your actual path

@onready var int_text = get_node("/root/" + get_tree().current_scene.name + "/UI/interact_text") # Verify path
var player # Get player reference once

func _ready():
	# Assuming player is always present at this path when raycast is ready
	player = get_node("/root/" + get_tree().current_scene.name + "/Player")
	if player == null:
		printerr("Raycast Error: Could not find Player node.")

func _process(delta):
	var show_text = false # Default to not showing text

	if is_colliding():
		var hit = get_collider()
		if hit != null and player != null: # Also ensure player reference is valid
			# Check if the object is interactable in general
			if hit.has_method("interact"):
				var can_show_interact_prompt = true # Assume yes, then check conditions to make it false

				# --- Specific check for Battery Pickups ---
				# Check if the hit object's script IS the BatteryPickup script
				if hit.get_script() == BatteryPickupScript:
					# Check player state: Must have obtained flashlight AND must NOT have a charge
					if not player.has_obtained_flashlight or player.has_flashlight_charge:
						can_show_interact_prompt = false # Do NOT show prompt if flashlight not obtained OR already charged
				# --- End specific check ---
				# (You could add 'elif' checks here for other interactable types if needed)


				# If all checks passed, allow showing text and interaction
				if can_show_interact_prompt:
					show_text = true
					if Input.is_action_just_pressed("interact"):
						print("Raycast: Calling interact() on ", hit.name) # DEBUG
						hit.interact()
				# else: # DEBUG (Optional)
					# print("Raycast: Hitting interactable ", hit.name, " but prompt hidden.")

	int_text.visible = show_text # Update text visibility ONLY if interaction is currently possible
