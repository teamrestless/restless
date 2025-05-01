# WinScreen.gd
extends Control

# How many seconds to show the win screen
@export var display_duration: float = 3.0
# Path to your main menu scene file
@export var main_menu_scene_path: String = "res://Scenes/main_menu.tscn"

func _ready():
	# Start a timer when the scene loads
	await get_tree().create_timer(display_duration).timeout
	# After the timer finishes, go back to the main menu
	go_to_main_menu()

func go_to_main_menu():
	var error = get_tree().change_scene_to_file(main_menu_scene_path)
	if error != OK:
		printerr("Error changing scene to main menu: ", error)
		# Fallback or alternative action if scene change fails
