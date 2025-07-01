extends Node2D

const GRID_SIZE = 20
const TILE_SIZE = 32
const PYRAMID_CENTER = Vector2i(10, 10)

var tiles: Array[Array] = []
var workers: Array[Worker] = []
var selected_worker: Worker = null

@onready var tile_container = $TileContainer
@onready var worker_container = $WorkerContainer
@onready var highlight_overlay = $HighlightOverlay

var worker_scene = preload("res://scenes/Worker.tscn")

func _ready():
	GameManager.register_game_board(self)
	_initialize_grid()
	_generate_map()
	_spawn_workers()

func _initialize_grid():
	# Initialize 2D array for tiles
	tiles.resize(GRID_SIZE)
	for x in range(GRID_SIZE):
		tiles[x] = []
		tiles[x].resize(GRID_SIZE)

func _generate_map():
	# Generate the game map
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			var tile = Tile.new()
			tile.grid_position = Vector2i(x, y)
			tile.position = Vector2(x * TILE_SIZE + TILE_SIZE/2, y * TILE_SIZE + TILE_SIZE/2)
			
			# Set terrain type based on position
			tile.terrain_type = _get_terrain_type(Vector2i(x, y))
			
			# Set stone deposit amounts
			if tile.terrain_type == Tile.TerrainType.STONE_DEPOSIT:
				tile.stone_deposit_remaining = 5  # Each deposit has 5 stones
			
			tiles[x][y] = tile
			tile_container.add_child(tile)

func _get_terrain_type(pos: Vector2i) -> Tile.TerrainType:
	# Pyramid base (3x3 in center)
	if pos.x >= PYRAMID_CENTER.x - 1 and pos.x <= PYRAMID_CENTER.x + 1 and \
	   pos.y >= PYRAMID_CENTER.y - 1 and pos.y <= PYRAMID_CENTER.y + 1:
		return Tile.TerrainType.PYRAMID_BASE
	
	# Generate Nile river (vertical strip)
	if pos.x >= 6 and pos.x <= 7:
		return Tile.TerrainType.WATER
	
	# Add some stone deposits (3 random locations, avoiding water and pyramid)
	var stone_positions = [
		Vector2i(3, 5),
		Vector2i(15, 8),
		Vector2i(12, 16)
	]
	
	if pos in stone_positions:
		return Tile.TerrainType.STONE_DEPOSIT
	
	# Everything else is desert
	return Tile.TerrainType.DESERT

func _spawn_workers():
	# Spawn 2 workers at predefined positions
	var worker_positions = [
		Vector2i(2, 10),
		Vector2i(18, 10)
	]
	
	for i in range(2):
		var worker = worker_scene.instantiate()
		worker.grid_position = worker_positions[i]
		worker.position = Vector2(worker_positions[i].x * TILE_SIZE + TILE_SIZE/2, 
								  worker_positions[i].y * TILE_SIZE + TILE_SIZE/2)
		
		workers.append(worker)
		worker_container.add_child(worker)
		GameManager.add_worker(worker)
	
	# Don't auto-select any worker - player must click to select

func handle_click(world_pos: Vector2):
	var grid_pos = world_to_grid(world_pos)
	
	if not is_valid_position(grid_pos):
		return
	
	# Check if clicking on a worker
	var worker_at_pos = get_worker_at_position(grid_pos)
	if worker_at_pos:
		_select_worker(worker_at_pos)
		return
	
	# Handle action with selected worker
	if selected_worker and GameManager.can_worker_act():
		_handle_worker_action(grid_pos)

func _select_worker(worker: Worker):
	if selected_worker:
		selected_worker.set_selected(false)
		_clear_tile_highlights()
	
	selected_worker = worker
	selected_worker.set_selected(true)
	GameManager.current_worker_index = workers.find(worker)
	_highlight_movement_range(worker)
	GameManager.worker_changed.emit()

func deselect_worker():
	if selected_worker:
		selected_worker.set_selected(false)
		selected_worker = null
		_clear_tile_highlights()
		GameManager.worker_changed.emit()

func _highlight_movement_range(worker: Worker):
	if not worker or worker.action_points <= 0:
		return
	
	var adjacent_positions = worker.get_adjacent_positions()
	
	for pos in adjacent_positions:
		if is_valid_position(pos):
			var tile = get_tile_at(pos)
			if tile:
				# Highlight based on what action is possible
				if tile.can_move_through() and not get_worker_at_position(pos):
					highlight_overlay.set_highlight(pos, true, Color.GREEN)  # Movement
				elif tile.can_quarry() and worker.can_quarry():
					highlight_overlay.set_highlight(pos, true, Color.YELLOW)  # Quarry
				elif tile.can_place_stone() and worker.can_place_stone():
					highlight_overlay.set_highlight(pos, true, Color.BLUE)  # Place stone

func _clear_tile_highlights():
	highlight_overlay.clear_all_highlights()

func _handle_worker_action(target_pos: Vector2i):
	if not selected_worker:
		return
	
	var tile = get_tile_at(target_pos)
	if not tile:
		return
	
	var worker_pos = selected_worker.grid_position
	var distance = abs(target_pos.x - worker_pos.x) + abs(target_pos.y - worker_pos.y)
	
	# Adjacent tile actions
	if distance == 1:
		# Try to quarry first (stone deposits are impassable)
		if tile.can_quarry() and selected_worker.can_quarry():
			if tile.quarry_stone() and selected_worker.quarry_stone():
				print("Worker quarried stone from ", target_pos)
		
		# Try to move
		elif tile.can_move_through() and not get_worker_at_position(target_pos):
			if selected_worker.move_to(target_pos):
				print("Worker moved to ", target_pos)
		
		# Try to place stone
		elif tile.can_place_stone() and selected_worker.can_place_stone():
			if tile.place_stone() and selected_worker.place_stone():
				print("Worker placed stone at ", target_pos)
	
	# Update highlights after action
	if selected_worker:
		_clear_tile_highlights()
		_highlight_movement_range(selected_worker)

func get_tile_at(pos: Vector2i) -> Tile:
	if is_valid_position(pos):
		return tiles[pos.x][pos.y]
	return null

func get_worker_at_position(pos: Vector2i) -> Worker:
	for worker in workers:
		if worker.grid_position == pos:
			return worker
	return null

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE/2, grid_pos.y * TILE_SIZE + TILE_SIZE/2)

func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE

func place_stone_at_worker_position():
	if not selected_worker:
		return
	
	var worker_pos = selected_worker.grid_position
	var tile = get_tile_at(worker_pos)
	
	if tile and tile.can_place_stone() and selected_worker.can_place_stone():
		if tile.place_stone() and selected_worker.place_stone():
			print("Worker placed stone at current position ", worker_pos)

func can_place_stone_at_worker_position(worker: Worker) -> bool:
	var tile = get_tile_at(worker.grid_position)
	return tile != null and tile.can_place_stone()

