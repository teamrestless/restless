extends Node3D

var player

# --- Battery Spawning Logic ---
@export var battery_pickup_scene: PackedScene # Assign BatteryPickup.tscn in Inspector
var battery_spawn_points: Array = []
var active_battery_pickup = null # Reference to the spawned battery

func _ready():
	player = get_node("/root/" + get_tree().current_scene.name + "/Player") # Keep if needed

	# --- Connect Player Signal ---
	if player and player.has_signal("flashlight_used"):
		player.flashlight_used.connect(request_new_battery)
	else:
		print("Warning: Could not connect flashlight_used signal from player.")

	# --- Find Battery Spawn Points ---
	# Add several Position3D nodes in your level scene
	# and add them to the "battery_spawn_points" group in the editor.
	battery_spawn_points = get_tree().get_nodes_in_group("battery_spawn_points")
	if battery_spawn_points.is_empty():
		print("Warning: No nodes found in group 'battery_spawn_points'!")

	# Optional: Spawn the first battery immediately if player starts without charge
	if player and not player.has_flashlight_charge:
		request_new_battery()


func _process(delta):
	# Keep your existing monster targeting logic
	if player:
		get_tree().call_group("monster", "update_target_location", player.global_transform.origin)


# --- Battery Spawning Functions ---
func request_new_battery():
	# Only spawn if there isn't already an active battery OR the active one is somehow invalid
	if (active_battery_pickup == null or not is_instance_valid(active_battery_pickup)) and not battery_spawn_points.is_empty():
		# Select a random spawn point (Using Marker3D group)
		var spawn_point = battery_spawn_points[randi() % battery_spawn_points.size()]

		# Instantiate battery
		if battery_pickup_scene:
			active_battery_pickup = battery_pickup_scene.instantiate()

			# Add to the main scene
			get_tree().current_scene.add_child(active_battery_pickup)
			# Set position using the spawn point's position
			active_battery_pickup.global_position = spawn_point.global_position

			# --- NEW: Add Random Rotation ---
			# 50% chance to lay it down
			if randi() % 2 == 0:
				# Rotate 90 degrees on either X or Z axis randomly
				if randi() % 2 == 0:
					active_battery_pickup.rotate_x(deg_to_rad(90.0))
					print("Spawned battery lying down (X-axis)") # Debug
				else:
					active_battery_pickup.rotate_z(deg_to_rad(90.0))
					print("Spawned battery lying down (Z-axis)") # Debug
			else:
				print("Spawned battery upright") # Debug
				# Optionally, apply the spawn point's rotation if you want some markers to pre-define orientation
				# active_battery_pickup.global_rotation = spawn_point.global_rotation
			# --- END Random Rotation ---
			# Connect to its picked_up signal
			active_battery_pickup.picked_up.connect(_on_battery_picked_up)
			print("Spawned new battery at: ", spawn_point.name) # Debug
		else:
			print("Error: Battery pickup scene not set in LevelManager!")


func _on_battery_picked_up():
	# The battery picked itself up and will queue_free itself.
	# We just need to clear our reference so a new one can spawn next time.
	print("Battery was picked up.") # Debug
	active_battery_pickup = null
