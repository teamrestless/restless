extends CharacterBody3D

# --- Vars ---
var ORIGINAL_SPEED
var SPEED = 3.0
var sprint_drain_amount = 0.3
var sprint_refresh_amount = 0.4
var SPRINT_SPEED = 7.0
#var sprint_slider
const JUMP_VELOCITY = 4.5

# --- Flashlight Vars ---
var has_obtained_flashlight: bool = false
var has_flashlight_charge: bool = false
var successful_monster_flashes: int = 0
const MAX_MONSTER_HITS = 3

# --- Node References ---
@onready var head = $head # Node3D containing camera and light
@onready var camera = $head/Camera3D # Reference the EXISTING Spotlight3D node, script should be removed from it
@onready var flashlight_light = $head/Camera3D/flashlight # Reference the NEW RayCast3D you will ADD as a child of Camera3D
@onready var flashlight_raycast = $head/Camera3D/FlashlightDamageRaycast # Reference the EXISTING sound under the flashlight node
@onready var flash_sound = $head/Camera3D/flashlight/toggle # Reference a NEW sound node you should ADD for the empty click
@onready var empty_sound = $EmptyClickSound # Reference the UI node (Ensure path is correct for your UI scene structure)
@onready var battery_ui = get_node(NodePath("/root/" + get_tree().current_scene.name + "/UI/BatteryIndicator")) # Reference sprint slider (Keep existing)
@onready var sprint_slider = get_node("/root/" + get_tree().current_scene.name + "/UI/sprint_slider")

# --- Signal declaration, texture exports ---
signal flashlight_used
@export var battery_full_texture: Texture
@export var battery_empty_texture: Texture

@onready var animation_tree : AnimationTree = $AnimationTree
var blend_value : = 0.0

# --- (Rest of the player.gd code: _ready, _physics_process, _use_flash, etc.) ---
# REMEMBER TO REMOVE the _input function handling mouse look from player.gd,
# as it's handled by camera.gd on the 'head' node.

func _ready():
	ORIGINAL_SPEED = SPEED
	flashlight_light.visible = false
	flashlight_raycast.enabled = true
	flashlight_raycast.exclude_parent = true
	update_battery_ui()
	sprint_slider.visible = false
	animation_tree.active = true

func _input(event: InputEvent) -> void:
	# Handle mouse look (keep your existing code from camera.gd if it's here,
	# or keep camera.gd separate if preferred)

	# --- Flashlight Input ---
	if Input.is_action_just_pressed("flashlight"): # Use the same input name as before
		if has_flashlight_charge:
			_use_flash()
		else:
			# Play empty sound if trying to flash without charge
			if empty_sound:
				empty_sound.play()

func _physics_process(delta: float) -> void:
	# --- Movement Code ---
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		if Input.is_action_just_pressed("sprint"):
			sprint_slider.visible = true
			SPEED = SPRINT_SPEED
		if Input.is_action_just_released("sprint"):
			SPEED = ORIGINAL_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

# --- Flashlight Logic ---
func _use_flash():
	# 1. Consume Charge
	has_flashlight_charge = false
	update_battery_ui()

	# 2. Visual Flash Effect
	flashlight_light.visible = true
	if flash_sound:
		flash_sound.play()
	await get_tree().create_timer(0.2).timeout # Timer remains the same
	flashlight_light.visible = false

	# 3. Perform RayCast Check
	print("Player: Firing flash raycast.") # DEBUG
	flashlight_raycast.force_raycast_update()
	if flashlight_raycast.is_colliding():
		var collider = flashlight_raycast.get_collider()
		print("  - Raycast Hit: ", collider) # DEBUG
		if collider != null:
			print("  - Hit object group: ", collider.get_groups()) # DEBUG - See all groups
			if collider.is_in_group("monsters"): # Check if it's specifically in the 'monsters' group
				if collider.has_method("take_flash_damage"):
					print("  - Calling take_flash_damage() on monster.") # DEBUG
					collider.take_flash_damage() # Just call the monster's function
				else:
					print("  - Error: Monster does not have take_flash_damage method.")
			else:
				print("  - Hit object not in 'monsters' group.") # DEBUG
		else:
			print("  - Raycast hit null collider?") # DEBUG
	else:
		print("  - Flash raycast hit nothing.") # DEBUG
	# 4. Signal that the flash was used (for battery spawning)
	emit_signal("flashlight_used")

func obtain_flashlight():
	if not has_obtained_flashlight: # Only run this logic once
		print("Flashlight Obtained!") # Debug
		has_obtained_flashlight = true
		# IMPORTANT: Do NOT set has_flashlight_charge = true here
		# Update the UI - this will now SHOW it (because has_obtained_flashlight is true)
		# and display the EMPTY texture (because has_flashlight_charge is false)
		update_battery_ui()

# Optional: Modify gain_flashlight_charge slightly for safety
func gain_flashlight_charge():
	# Only allow gaining charge if the flashlight has been obtained first
	if not has_obtained_flashlight:
		print("Tried to gain charge, but flashlight not obtained yet.") # Debug
		return

	if not has_flashlight_charge: # Only gain if currently empty
		has_flashlight_charge = true
		update_battery_ui() # Update UI to show full battery
		# Optional: Play a sound for picking up the battery

func update_battery_ui():
	if not battery_ui:
		print("Warning: battery_ui node not found or invalid.")
		return # Exit if the UI node isn't valid

	if not has_obtained_flashlight:
		battery_ui.hide() # Hide the UI completely if flashlight not picked up yet
		return # Don't process textures if hidden

	# If we reach here, the flashlight HAS been obtained, so show the UI
	battery_ui.show()

	# Now determine which texture to display (full or empty)
	if has_flashlight_charge:
		if battery_full_texture:
			battery_ui.texture = battery_full_texture
		else:
			print("Warning: battery_full_texture not set in player script.")
			# Optionally set a default color or placeholder if texture missing
			battery_ui.texture = null # Clear texture if missing
	else:
		if battery_empty_texture:
			battery_ui.texture = battery_empty_texture
		else:
			print("Warning: battery_empty_texture not set in player script.")
			# Optionally set a default color or placeholder if texture missing
			battery_ui.texture = null # Clear texture if missing

# --- Sprint logic ---
func _process(delta):
	update_animation_parameters()
	if SPEED == SPRINT_SPEED:
		sprint_slider.value = sprint_slider.value - sprint_drain_amount * delta
		if sprint_slider.value == sprint_slider.min_value:
			SPEED = ORIGINAL_SPEED
	if SPEED != SPRINT_SPEED:
		if sprint_slider.value < sprint_slider.max_value:
			sprint_slider.value = sprint_slider.value + sprint_refresh_amount * delta
		if sprint_slider.value == sprint_slider.max_value:
			sprint_slider.visible = false

func update_animation_parameters():
	# Use Vector3.ZERO for 3D characters
	if velocity == Vector3.ZERO:
		animation_tree["parameters/StateMachine/conditions/Idle"] = true
		animation_tree["parameters/StateMachine/conditions/Is Moving"] = false
	else:
		animation_tree["parameters/StateMachine/conditions/Idle"] = false
		animation_tree["parameters/StateMachine/conditions/Is Moving"] = true
	if Input.is_action_pressed("sprint"):
		animation_tree["parameters/StateMachine/conditions/Running"] = true
		animation_tree["parameters/StateMachine/conditions/Is Moving"] = false
	if Input.is_action_just_released("sprint"):
		animation_tree["parameters/StateMachine/conditions/Running"] = false
		animation_tree["parameters/StateMachine/conditions/Is Moving"] = true
