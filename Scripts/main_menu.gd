# main_menu.gd
extends Control

func _ready():
	# Ensure the mouse cursor is visible and free when the main menu loads
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func play():
	# --- IMPORTANT: Re-capture mouse when starting gameplay ---
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# --- End addition ---
	get_tree().change_scene_to_file("res://Scenes/level0.tscn") # Or your starting level

func quit():
	get_tree().quit()
