extends Control

func _ready():
	# Connect Back Button
	# Assumes the button is the last child or named specifically. 
	# Let's find it by type to be safe, or you can rename your button node to 'BtnBack'
	for child in get_children():
		if child is TextureButton and child.texture_normal.resource_path.contains("ButtonBack"):
			child.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn"))
	
	# Connect Level Buttons
	var lvl = 1
	var grid = $GridContainer
	for btn in grid.get_children():
		if btn is TextureButton:
			btn.pressed.connect(func(): 
				Global.current_level = lvl
				get_tree().change_scene_to_file("res://Scenes/Game.tscn")
			)
			lvl += 1
