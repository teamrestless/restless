extends Control

func play():
	get_tree().change_scene_to_file("res://Scenes/level0.tscn")
	
func quit():
	get_tree().quit()
