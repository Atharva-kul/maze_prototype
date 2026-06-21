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
	
	pass # Replace with function body.

func reset_maze():
	maze = []
	
	for r in range(ROWS):
		var row = []
		for c in range(COLS):
			row.append(1)
		maze.append(row)
	#print(maze)
	pass
	
func generate_maze():
	reset_maze()
	var start_row = 1
	var start_col = 1
	
	maze[start_row][start_col] = 0
	#print(maze)
	
	carve_passage(start_row, start_col)
	print(maze)
	draw_maze()
	spawn_char(10)
	spawn_coin(10)
	
	pass

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

	
	pass
	
func draw_maze():
	tile_map_layer.clear()
	
	for r in range(ROWS):
		for c in range(COLS):
			var tile_type = wall if maze[r][c] == 1 else path
			tile_map_layer.set_cell(Vector2i(c,  r), 0, tile_type) # here 0 is image source id
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func spawn_char(amount: int) -> void:
	# 1. Clear out previous clones when you regenerate the maze
	
	for child in get_children():
		if child.is_in_group("enemy") and child.name != "enemy":
			
			child.queue_free()
			
		
	var original_enemy = $enemy as CharacterBody2D

	# 3. Gather all path coordinates from your generated maze array
	var path_cells: Array[Vector2i] = []
	for r in range(ROWS):
		for c in range(COLS):
			if maze[r][c] == 0: # 0 means path
				path_cells.append(Vector2i(c, r))
	
	# Shuffle the paths for complete randomness
	path_cells.shuffle()
	
	# Safety check: don't spawn more than available path tiles
	if path_cells.size() < amount:
		amount = path_cells.size()

	# 4. Clone loop
	for i in range(amount):
		var target_cell = path_cells[i]
		
		# CRUCIAL: Duplicate the pre-existing enemy node, including its script and sprites!
		var new_enemy = original_enemy.duplicate() as CharacterBody2D
		
		# Tag the clones so we can safely delete them on map reset
		
		# Ensure it still triggers your damage detection group from earlier
		new_enemy.add_to_group("enemy") 
		
		# Convert grid tile to global pixels
		var tile_center = tile_map_layer.map_to_local(target_cell)
		var global_spawn_pos = tile_map_layer.to_global(tile_center)
		
		# Position the clone
		new_enemy.global_position = global_spawn_pos
		
		# Add it into your active game world
		add_child(new_enemy)
		
		# Tell the new clone to pick its random starting direction
		if new_enemy.has_method("pick_random_direction"):
			new_enemy.pick_random_direction()

	# 5. Hide and disable the original master copy so it doesn't just sit there
	original_enemy.visible = false
	original_enemy.process_mode = PROCESS_MODE_DISABLED
	
func spawn_coin(amount: int) -> void:
	# 1. Clear out previous clones when you regenerate the maze
	for child in get_children():
		if child.is_in_group("coin") and child.name != "coin":
			child.queue_free()
		
	var original_coin = $coin as StaticBody2D

	# 3. Gather all path coordinates from your generated maze array
	var path_cells: Array[Vector2i] = []
	for r in range(ROWS):
		for c in range(COLS):
			if maze[r][c] == 0: # 0 means path
				path_cells.append(Vector2i(c, r))
	
	# Shuffle the paths for complete randomness
	path_cells.shuffle()
	
	# Safety check: don't spawn more than available path tiles
	if path_cells.size() < amount:
		amount = path_cells.size()

	# 4. Clone loop
	for i in range(amount):
		var target_cell = path_cells[i]
		
		# CRUCIAL: Duplicate the pre-existing enemy node, including its script and sprites!
		var new_coin = original_coin.duplicate() as StaticBody2D
		
		# Tag the clones so we can safely delete them on map reset
		
		# Ensure it still triggers your damage detection group from earlier
		new_coin.add_to_group("coin") 
		
		# Convert grid tile to global pixels
		var tile_center = tile_map_layer.map_to_local(target_cell)
		var global_spawn_pos = tile_map_layer.to_global(tile_center)
		
		# Position the clone
		new_coin.global_position = global_spawn_pos
		
		# Add it into your active game world
		add_child(new_coin)
		
		

	# 5. Hide and disable the original master copy so it doesn't just sit there
	original_coin.visible = false
	original_coin.process_mode = PROCESS_MODE_DISABLED
	
	
func _on_button_pressed() -> void:
	generate_maze()
