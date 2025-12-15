extends Control

# This path MUST match your file exactly. Check capitalization!
var level_select_path = "res://Scenes/LevelSelect.tscn"

func _ready():
	print("--- GAME STARTED ---")
	
	# 1. Find the Play Button automatically
	var btn = null
	for child in get_children():
		if child is TextureButton:
			btn = child
			break
	
	# 2. Connect it
	if btn:
		print("✅ BUTTON FOUND: " + btn.name)
		# Disconnect old signals to prevent errors
		if btn.pressed.is_connected(_on_play_pressed):
			btn.pressed.disconnect(_on_play_pressed)
		
		btn.pressed.connect(_on_play_pressed)
	else:
		print("❌ ERROR: Screen is empty! You forgot to add a TextureButton.")

func _on_play_pressed():
	print("🖱️ CLICK! Trying to change scene to: " + level_select_path)
	
	# 3. Check if the next scene actually exists
	if ResourceLoader.exists(level_select_path):
		get_tree().change_scene_to_file(level_select_path)
	else:
		print("❌ CRITICAL ERROR: The file '" + level_select_path + "' does not exist!")
		print("   Make sure you saved your Level Select scene in the 'Scenes' folder!")
