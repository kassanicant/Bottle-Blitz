extends Control

# --- CONFIGURATION ---
var box_texture = preload("res://ASsets/CardboardBox.png")
var bottle_textures = [
	preload("res://ASsets/Bottles/Blue.png"),
	preload("res://ASsets/Bottles/Green.png"),
	preload("res://ASsets/Bottles/Red.png"),
	preload("res://ASsets/Bottles/Yellow.png"),
	preload("res://ASsets/Bottles/Purple.png"),
	preload("res://ASsets/Bottles/Orange.png"),
	preload("res://ASsets/Bottles/Pink.png"),
	preload("res://ASsets/Bottles/White.png"),
	preload("res://ASsets/Bottles/Black.png"),
	preload("res://ASsets/Bottles/Cyan.png"),
	preload("res://ASsets/Bottles/Lime.png"),
	preload("res://ASsets/Bottles/Magenta.png"),
	preload("res://ASsets/Bottles/Violet.png"),
	preload("res://ASsets/Bottles/Forest_Green.png")
]

# --- NODES ---
@onready var grid_container = find_child("BoxGrid", true, false)
@onready var bench_slots = find_child("Slots", true, false)
@onready var score_label = find_child("ScoreLabel", true, false)
@onready var timer_label = find_child("TimerLabel", true, false)
@onready var btn_next = find_child("BtnNext", true, false)
@onready var btn_back = find_child("BtnBack", true, false)
@onready var btn_reset = find_child("BtnReset", true, false)

# --- VARIABLES ---
var current_level = 1
var time_left = 60
var matches_needed = 0
var timer_node = Timer.new()

# --- INNER CLASSES ---

# 1. BOTTLE LOGIC
class BottlePiece extends TextureRect:
	var bottle_id = -1
	func setup(tex, id):
		texture = tex
		bottle_id = id
		expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		custom_minimum_size = Vector2(60, 80)
		mouse_filter = Control.MOUSE_FILTER_STOP
		
	func _get_drag_data(_at_pos):
		var preview = TextureRect.new()
		preview.texture = texture
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.size = size
		preview.modulate.a = 0.7
		set_drag_preview(preview)
		return self

# 2. BENCH LOGIC
class BenchScript extends HBoxContainer:
	func _can_drop_data(_at_pos, data):
		return data is BottlePiece

	func _drop_data(_at_pos, data):
		var source = data.get_parent()
		source.remove_child(data)
		add_child(data)

# 3. BOX LOGIC
class GameBox extends TextureRect:
	signal box_updated
	var my_correct_id = -1
	var hidden_sprite = Sprite2D.new()
	var slot = CenterContainer.new()
	var is_locked = false
	
	func setup(b_tex, correct_id):
		texture = b_tex
		my_correct_id = correct_id
		expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		custom_minimum_size = Vector2(100, 100)
		
		hidden_sprite.position = Vector2(50, 50)
		hidden_sprite.visible = false
		add_child(hidden_sprite)
		
		slot.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(slot)

	func set_hidden_texture(tex):
		hidden_sprite.texture = tex

	func _can_drop_data(_at_pos, data):
		return not is_locked and data is BottlePiece

	func _drop_data(_at_pos, new_bottle):
		var old_parent = new_bottle.get_parent()
		if old_parent == slot: return

		# Swap Logic
		if slot.get_child_count() > 0:
			var current_bottle = slot.get_child(0)
			slot.remove_child(current_bottle)
			old_parent.add_child(current_bottle)
		
		old_parent.remove_child(new_bottle)
		slot.add_child(new_bottle)
		box_updated.emit()
	
	func _notification(what):
		if what == NOTIFICATION_CHILD_ORDER_CHANGED:
			box_updated.emit()

# --- MAIN LOGIC ---

func _ready():
	add_child(timer_node)
	timer_node.timeout.connect(_on_timer)
	
	if btn_back: btn_back.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/LevelSelect.tscn"))
	if btn_next: btn_next.pressed.connect(next_level)
	if btn_reset: btn_reset.pressed.connect(start_level)
	
	if bench_slots: bench_slots.set_script(BenchScript)
	if Global.current_level: current_level = Global.current_level
	start_level()

func start_level():
	# Reset Buttons
	if btn_next: btn_next.visible = false
	if btn_reset: btn_reset.visible = false
	if score_label: score_label.text = "Matches: 0"
	
	# Config
	var boxes_count = 3
	var dummies = 0
	if current_level == 2: boxes_count = 4
	if current_level == 3: boxes_count = 6
	if current_level == 4: boxes_count = 8; dummies = 2
	if current_level == 5: boxes_count = 10; dummies = 3
	if current_level == 6: boxes_count = 12; dummies = 4
	
	matches_needed = boxes_count
	time_left = 60 + (current_level * 10)
	update_ui(0)
	
	# Clear Old Items
	for c in grid_container.get_children(): c.queue_free()
	for c in bench_slots.get_children(): c.queue_free()
	
	# Prepare Data
	var indices = range(bottle_textures.size())
	indices.shuffle()
	var level_ids = indices.slice(0, boxes_count)
	
	# Spawn Boxes
	for id in level_ids:
		var box = GameBox.new()
		grid_container.add_child(box)
		box.setup(box_texture, id)
		box.set_hidden_texture(bottle_textures[id])
		box.box_updated.connect(check_win)
	
	# Spawn Bottles
	var bottle_ids = level_ids.duplicate()
	if dummies > 0:
		bottle_ids.append_array(indices.slice(boxes_count, boxes_count+dummies))
	bottle_ids.shuffle()
	
	for id in bottle_ids:
		var piece = BottlePiece.new()
		bench_slots.add_child(piece)
		piece.setup(bottle_textures[id], id)
		
	timer_node.start()

func _on_timer():
	time_left -= 1
	if timer_label: timer_label.text = "" + str(time_left)
	if time_left <= 0:
		game_over(false)

func check_win():
	var score = 0
	for box in grid_container.get_children():
		if box.slot.get_child_count() > 0:
			var item = box.slot.get_child(0)
			if item.bottle_id == box.my_correct_id:
				score += 1
	
	update_ui(score)
	if score == matches_needed:
		game_over(true)

func game_over(is_win):
	timer_node.stop()
	
	if is_win:
		# 1. DELETE EVERYTHING ON SCREEN
		for c in grid_container.get_children(): c.queue_free()
		for c in bench_slots.get_children(): c.queue_free()
		
		# 2. SHOW CONGRATULATIONS
		if score_label: score_label.text = "CONGRATULATIONS!\nYOU CLEARED LEVEL " + str(current_level)
		
		# 3. SHOW BUTTONS
		if btn_next: btn_next.visible = true
		if btn_reset: btn_reset.visible = true
	else:
		if score_label: score_label.text = "GAME OVER!"
		if btn_reset: btn_reset.visible = true

func update_ui(score):
	if score_label: score_label.text = "" + str(score) + "/" + str(matches_needed)

func next_level():
	if current_level < 6:
		Global.current_level += 1
		current_level += 1
		start_level()
	else:
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
