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

# --- Stun Vars ---
var is_stunned: bool = false
@export var stun_duration: float = 4.0
@export var dizzy_angle_degrees: float = 20.0
@export var dizzy_cycle_time: float = 0.8

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
	# --- Apply gravity first (usually safe even if stunned/caught) ---
	if not is_on_floor():
		velocity.y -= gravity * delta

	# --- Main Logic Check ---
	# Only run AI/movement if visible AND not defeated AND not caught AND NOT stunned
	if visible and not is_defeated and not caught and not is_stunned:
		var current_location = global_transform.origin
		var next_location = $NavigationAgent3D.get_next_path_position()
		var new_velocity = (next_location - current_location).normalized() * SPEED

		# Check if speed > 0 before setting velocity and rotating
		if SPEED > 0:
			$NavigationAgent3D.set_velocity(new_velocity)
			# Only rotate based on velocity if actually moving
			if new_velocity.length_squared() > 0.01:
				var look_dir = atan2(-new_velocity.x, -new_velocity.z)
				rotation.y = look_dir

		# Distance check for jumpscare (might need adjustment if stun prevents getting close)
		distance = player.global_transform.origin.distance_to(global_transform.origin)
		if distance <= 2:
			_jumpscare()

		# Apply calculated velocity only if not stunned/caught/defeated
		move_and_slide()

	elif is_stunned:
		# Apply only gravity while stunned, keep horizontal velocity zero
		velocity.x = 0
		velocity.z = 0
		move_and_slide()

	# Handle other states (caught, defeated) if needed, maybe just gravity applies
	elif caught or is_defeated:
		# Potentially just apply gravity
		velocity.x = 0
		velocity.z = 0
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
# Ignore if already defeated OR already stunned
	if is_defeated or is_stunned:
		print("Monster: take_flash_damage ignored (defeated or already stunned).") # DEBUG
		return

	print("Monster: take_flash_damage() received!") # DEBUG
	flash_hits += 1
	print("  - Monster flash_hits now: ", flash_hits) # DEBUG

	# --- Trigger Stun and Animation ---
	is_stunned = true
	print("  - Monster STUNNED.") # DEBUG
	# Stop current movement immediately
	velocity = Vector3.ZERO
	if $NavigationAgent3D: # Check if node exists
		$NavigationAgent3D.set_velocity(Vector3.ZERO) # Stop navigation agent too

	# Play the dizzy animation asynchronously (doesn't block the rest)
	_play_dizzy_animation()

	# Play hit sound (if exists)
	# if hit_sound: hit_sound.play()

	# Start a timer to reset the stun state later
	# Use call_deferred to ensure it runs safely even if the node is freed during the timer
	get_tree().create_timer(stun_duration).timeout.connect(Callable(self, "_reset_stun").bind(), CONNECT_ONE_SHOT)
	# --- End Stun Trigger ---


	# Check for death AFTER applying stun effects
	if flash_hits >= HITS_TO_DEFEAT:
		print("  - Hit count threshold reached! Calling die().") # DEBUG
		die() # Die function will handle overriding stun if needed
	else:
		print("  - Hit count ", flash_hits, "/", HITS_TO_DEFEAT) # DEBUG

# --- NEW Function to Reset Stun ---
func _reset_stun():
	# This function is called by the timer after stun_duration
	# Important: Check if the instance is still valid (might have been defeated/freed)
	if not is_instance_valid(self):
		return

	# Only reset stun if not defeated in the meantime
	if not is_defeated:
		is_stunned = false
		print("Monster: Stun finished.") # DEBUG
	else:
		print("Monster: Stun timer finished, but monster was already defeated.") # DEBUG


# --- NEW Function for Dizzy Animation ---
func _play_dizzy_animation():
	print("Monster: Playing dizzy animation...") # DEBUG
	# Ensure we have a valid node instance
	if not is_instance_valid(self):
		return

	var tween = create_tween().set_loops(2) # Loop the left-right cycle twice
	tween.set_parallel(false) # Run animation steps sequentially

	var start_rotation_y = rotation.y
	var dizzy_rads = deg_to_rad(dizzy_angle_degrees)
	var segment_time = dizzy_cycle_time / 4.0 # Divide cycle into 4 parts: left, right, right, left(back to center)

	# 1. Turn Left
	tween.tween_property(self, "rotation:y", start_rotation_y + dizzy_rads, segment_time).set_ease(Tween.EASE_OUT_IN)
	# 2. Turn Right (past center)
	tween.tween_property(self, "rotation:y", start_rotation_y - dizzy_rads, segment_time * 2.0).set_ease(Tween.EASE_OUT_IN) # Double time for full swing
	# 3. Turn back to Center-ish (original start rotation)
	tween.tween_property(self, "rotation:y", start_rotation_y, segment_time).set_ease(Tween.EASE_OUT_IN)

	# Optional: Add a callback if needed when the tween finishes
	# tween.finished.connect(func(): print("Dizzy animation finished"))

# --- New Death Function ---
func die():
	if is_defeated:
		print("Monster: die() called, but already defeated.") # DEBUG
		return

	print("Monster: die() function called!") # DEBUG
	is_defeated = true
	is_stunned = false
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
