extends CharacterBody3D

# --- Vars ---
var SPEED = 4
var jumpscareTime = 2
var player
var caught = false
var distance: float
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- Flashlight Vars ---
var flash_hits: int = 0
const HITS_TO_DEFEAT: int = 3
var is_defeated: bool = false

@onready var hit_sound = $HitSound # ADD AudioStreamPlayer for hit reaction
@onready var death_sound = $DeathSound # ADD AudioStreamPlayer for death
@onready var animation_player = $AnimationPlayer # ADD AnimationPlayer if you have hit/death anims

@export var scene_name: String
@export var totem_scene: PackedScene # Assign your Totem.tscn in the Inspector

func _ready():
	player = get_node("/root/" + get_tree().current_scene.name + "/Player")
	add_to_group("monsters")
	print("Monster added to group 'monsters': ", is_in_group("monsters")) # DEBUG

func _physics_process(delta: float) -> void:
	if visible and not is_defeated and not caught:
		if not is_on_floor():
			velocity.y -= gravity * delta
		
		var current_location = global_transform.origin
		var next_location = $NavigationAgent3D.get_next_path_position()
		var new_velocity = (next_location - current_location).normalized() * SPEED
		
		if SPEED > 0:
			$NavigationAgent3D.set_velocity(new_velocity)
		
		var look_dir = atan2(-new_velocity.x, -new_velocity.z)
		rotation.y = look_dir
		distance = player.global_transform.origin.distance_to(global_transform.origin)
		if distance <= 2:
			_jumpscare()
	elif is_defeated:
		pass
	else:
		if not is_on_floor():
			velocity.y -= gravity * delta
			move_and_slide()

func _jumpscare():
	player.visible = false
	if !$jumpscare.playing:
		$jumpscare.play()
	SPEED = 0 # Stop movement
	caught = true
	$jumpscare_camera.current = true
	await get_tree().create_timer(jumpscareTime, false).timeout
	# Only change scene if the monster wasn't defeated by flashing
	if not is_defeated:
		get_tree().change_scene_to_file("res://Scenes/" + scene_name + ".tscn") # Existing death scene

func update_target_location(target_location):
	# Only update target if active
	if visible and not is_defeated and not caught:
		$NavigationAgent3D.target_position = target_location

func on_navigation_agent_3d_velocity_computed(safe_velocity):
	 # Only move if active
	if visible and not is_defeated and not caught:
		velocity = velocity.move_toward(safe_velocity, 0.25)
		move_and_slide()

# --- Flashlight Damage Function ---
func take_flash_damage():
	if is_defeated:
		print("Monster: take_flash_damage called, but already defeated.") # DEBUG
		return

	print("Monster: take_flash_damage() received!") # DEBUG
	flash_hits += 1
	print("  - Monster flash_hits now: ", flash_hits) # DEBUG

	# Play hit reaction (sound/animation) if they exist
	# if hit_sound: hit_sound.play()
	# if animation_player and animation_player.has_animation("hit"): animation_player.play("hit")

	if flash_hits >= HITS_TO_DEFEAT:
		print("  - Hit count threshold reached! Calling die().") # DEBUG
		die()
	else:
		print("  - Hit count ", flash_hits, "/", HITS_TO_DEFEAT) # DEBUG

# --- New Death Function ---
func die():
	if is_defeated:
		print("Monster: die() called, but already defeated.") # DEBUG
		return

	print("Monster: die() function called!") # DEBUG
	is_defeated = true
	SPEED = 0
	set_process(false)
	set_physics_process(false)
	# Disable collision shape - adjust name if needed
	var col_shape = $CollisionShape3D # Or the correct path/name
	if col_shape:
		col_shape.disabled = true
		print("  - Disabled CollisionShape3D.") # DEBUG
	else:
		print("  - Warning: Could not find CollisionShape3D to disable.") # DEBUG

	# Stop navigation agent if it exists
	var nav_agent = $NavigationAgent3D # Or the correct path/name
	if nav_agent:
		nav_agent.set_velocity(Vector3.ZERO)
		print("  - Stopped NavigationAgent3D.") # DEBUG
	else:
		print("  - Warning: Could not find NavigationAgent3D.") # DEBUG


	# Play death effects (sound/animation)
	# Ensure sounds/anims are ready and paths/names are correct
	# if death_sound: death_sound.play()
	# if animation_player and animation_player.has_animation("death"):
	#     animation_player.play("death")
	#     await animation_player.animation_finished
	# else:
	#     await get_tree().create_timer(0.5).timeout

	# Spawn Totem
	print("  - Checking totem scene...") # DEBUG
	if totem_scene != null:
		print("  - Totem scene IS assigned. Instantiating...") # DEBUG
		var totem_instance = totem_scene.instantiate()
		if totem_instance != null:
			get_tree().current_scene.add_child(totem_instance)
			totem_instance.global_position = self.global_position
			print("  - Totem instance added to scene at ", self.global_position) # DEBUG
		else:
			printerr("  - Error: Failed to instantiate totem scene!") # DEBUG
	else:
		printerr("  - Error: totem_scene PackedScene is NOT assigned in the Inspector!") # DEBUG

	# Remove Monster AFTER potentially waiting for animations/sounds or spawning totem
	print("  - Monster queue_free() called.") # DEBUG
	queue_free()
