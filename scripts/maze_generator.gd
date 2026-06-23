extends Node2D

@export var character_scene: PackedScene
@onready var tile_map_layer = $TileMapLayer


const ROWS = 25
const COLS = 25
const wall = Vector2i(0, 0)
const path = Vector2i(1, 0)

var maze = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate_maze()

func reset_maze():
	maze = []
	for r in range(ROWS):
		var row = []
		for c in range(COLS):
			row.append(1)
		maze.append(row)

func generate_maze():
	reset_maze()
	var start_row = 1
	var start_col = 1
	
	maze[start_row][start_col] = 0
	
	carve_passage(start_row, start_col)
	draw_maze()
	spawn_char(10)
	spawn_coin(5)

func carve_passage(row, col):
	var directions = [
		[-2, 0], #up
		[0, 2], #right
		[2, 0], #down
		[0, -2] #left
	]
	
	directions.shuffle()
	
	for dir in directions:
		var dr = dir[0]
		var dc = dir[1]
		
		var new_row = row+dr
		var new_col = col+dc
		
		if ( new_row > 0 and new_row < ROWS - 1 and new_col > 0 and new_col < COLS - 1 and maze[new_row][new_col] == 1 ):
			maze[new_row][new_col] = 0
			maze[row + int(dr / 2)][col + int(dc / 2)] = 0
			
			carve_passage(new_row, new_col)

func draw_maze():
	tile_map_layer.clear()
	for r in range(ROWS):
		for c in range(COLS):
			var tile_type = wall if maze[r][c] == 1 else path
			tile_map_layer.set_cell(Vector2i(c, r), 0, tile_type)

func _process(delta: float) -> void:
	pass

func spawn_char(amount: int) -> void:
	var original_enemy = $enemy as CharacterBody2D
	if not original_enemy:
		print("Error: Master enemy node not found!")
		return

	# 1. Clear out previous clones when you regenerate the maze
	for child in get_children():
		if child.is_in_group("enemy") and child != original_enemy:
			child.queue_free()

	# 2. Gather all path coordinates from your generated maze array
	var path_cells: Array[Vector2i] = []
	for r in range(ROWS):
		for c in range(COLS):
			if maze[r][c] == 0: # 0 means path
				path_cells.append(Vector2i(c, r))
	
	path_cells.shuffle()
	if path_cells.size() < amount:
		amount = path_cells.size()

	# 3. Clone loop
	for i in range(amount):
		var target_cell = path_cells[i]
		var new_enemy = original_enemy.duplicate() as CharacterBody2D
		
		new_enemy.visible = true
		new_enemy.process_mode = PROCESS_MODE_INHERIT
		new_enemy.add_to_group("enemy") 
		
		var tile_center = tile_map_layer.map_to_local(target_cell)
		var global_spawn_pos = tile_map_layer.to_global(tile_center)
		
		new_enemy.global_position = global_spawn_pos
		add_child(new_enemy)
		
		if new_enemy.has_method("pick_random_direction"):
			new_enemy.pick_random_direction()

	original_enemy.visible = false
	original_enemy.process_mode = PROCESS_MODE_DISABLED

func spawn_coin(amount: int) -> void:
	var original_coin = $coin as StaticBody2D
	if not original_coin:
		print("Error: Master coin node not found!")
		return

	# 1. Clear out previous clones when you regenerate the maze
	for child in get_children():
		if child.is_in_group("coin") and child != original_coin:
			child.queue_free()

	# 2. Gather all path coordinates from your generated maze array
	var path_cells: Array[Vector2i] = []
	for r in range(ROWS):
		for c in range(COLS):
			if maze[r][c] == 0: # 0 means path
				path_cells.append(Vector2i(c, r))
	
	path_cells.shuffle()
	if path_cells.size() < amount:
		amount = path_cells.size()

	# 3. Clone loop
	for i in range(amount):
		var target_cell = path_cells[i]
		var new_coin = original_coin.duplicate() as StaticBody2D
		
		new_coin.visible = true
		new_coin.process_mode = PROCESS_MODE_INHERIT
		new_coin.add_to_group("coin") 
		
		var tile_center = tile_map_layer.map_to_local(target_cell)
		var global_spawn_pos = tile_map_layer.to_global(tile_center)
		
		new_coin.global_position = global_spawn_pos
		add_child(new_coin)

	original_coin.visible = false
	original_coin.process_mode = PROCESS_MODE_DISABLED

# =========================================================================
# FIXED BUTTON INPUT SIGNALS
# =========================================================================
func _on_button_pressed() -> void:
	# 1. Regenerate the maze structural map layout completely
	generate_maze()
	
	# 2. Clear out the UI focus from this button immediately.
	# This resets gui_get_focus_owner() back to null so the player's 
	# shoot() verification check lets you fire guns right away!
	get_viewport().gui_release_focus()
