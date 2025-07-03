class_name TestDataBuilder
extends RefCounted

# Test Data Builder Pattern
# Provides convenient methods for creating test objects with default or customized values

# Worker creation helpers
static func create_worker(
	position: Vector2i = Vector2i(5, 5),
	action_points: int = 2,
	carried_stones: int = 0,
	max_stones: int = 1,
	is_selected: bool = false
) -> Worker:
	var worker = Worker.new()
	worker.grid_position = position
	worker.action_points = action_points
	worker.carried_stones = carried_stones
	worker.max_stones = max_stones
	worker.is_selected = is_selected
	return worker

static func create_exhausted_worker(position: Vector2i = Vector2i(5, 5)) -> Worker:
	return create_worker(position, 0, 0, 1, false)

static func create_worker_with_stone(position: Vector2i = Vector2i(5, 5)) -> Worker:
	return create_worker(position, 2, 1, 1, false)

static func create_selected_worker(position: Vector2i = Vector2i(5, 5)) -> Worker:
	return create_worker(position, 2, 0, 1, true)

# Tile creation helpers
static func create_tile(
	position: Vector2i = Vector2i(5, 5),
	terrain_type: Tile.TerrainType = Tile.TerrainType.DESERT,
	has_stone_block: bool = false,
	stone_deposit_remaining: int = 0
) -> Tile:
	var tile = Tile.new()
	tile.grid_position = position
	tile.terrain_type = terrain_type
	tile.has_stone_block = has_stone_block
	tile.stone_deposit_remaining = stone_deposit_remaining
	return tile

static func create_desert_tile(position: Vector2i = Vector2i(5, 5)) -> Tile:
	return create_tile(position, Tile.TerrainType.DESERT, false, 0)

static func create_water_tile(position: Vector2i = Vector2i(5, 5)) -> Tile:
	return create_tile(position, Tile.TerrainType.WATER, false, 0)

static func create_stone_deposit_tile(
	position: Vector2i = Vector2i(5, 5),
	remaining_stones: int = 5
) -> Tile:
	return create_tile(position, Tile.TerrainType.STONE_DEPOSIT, false, remaining_stones)

static func create_pyramid_base_tile(
	position: Vector2i = Vector2i(10, 10),
	has_stone: bool = false
) -> Tile:
	return create_tile(position, Tile.TerrainType.PYRAMID_BASE, has_stone, 0)

static func create_tile_with_stone(position: Vector2i = Vector2i(5, 5)) -> Tile:
	return create_tile(position, Tile.TerrainType.DESERT, true, 0)

# GameManager creation helpers
static func create_game_manager_with_workers(worker_count: int = 2) -> GameManager:
	var game_manager = GameManager.new()
	
	for i in range(worker_count):
		var worker = create_worker(Vector2i(2 + i * 16, 10))
		game_manager.add_worker(worker)
	
	return game_manager

static func create_game_manager_with_exhausted_workers() -> GameManager:
	var game_manager = GameManager.new()
	
	var worker1 = create_exhausted_worker(Vector2i(2, 10))
	var worker2 = create_exhausted_worker(Vector2i(18, 10))
	
	game_manager.add_worker(worker1)
	game_manager.add_worker(worker2)
	
	return game_manager

# GameBoard creation helpers
static func create_minimal_game_board() -> GameBoard:
	var board = GameBoard.new()
	board._initialize_grid()
	return board

static func create_game_board_with_tiles() -> GameBoard:
	var board = GameBoard.new()
	board._initialize_grid()
	board._generate_map()
	return board

static func create_game_board_with_workers() -> GameBoard:
	var board = create_game_board_with_tiles()
	board._spawn_workers()
	return board

# Specific game scenario builders
static func create_pyramid_completion_scenario() -> Dictionary:
	var game_manager = create_game_manager_with_workers()
	var board = create_game_board_with_tiles()
	
	# Fill pyramid base with stones
	for x in range(9, 12):
		for y in range(9, 12):
			var tile = board.get_tile_at(Vector2i(x, y))
			if tile:
				tile.has_stone_block = true
	
	return {
		"game_manager": game_manager,
		"board": board
	}

static func create_worker_near_stone_deposit() -> Dictionary:
	var worker = create_worker(Vector2i(3, 4))  # Adjacent to stone deposit at (3,5)
	var tile = create_stone_deposit_tile(Vector2i(3, 5), 5)
	
	return {
		"worker": worker,
		"stone_deposit": tile
	}

static func create_worker_at_pyramid_base() -> Dictionary:
	var worker = create_worker_with_stone(Vector2i(10, 10))
	var tile = create_pyramid_base_tile(Vector2i(10, 10), false)
	
	return {
		"worker": worker,
		"pyramid_tile": tile
	}

static func create_turn_progression_scenario() -> Dictionary:
	var game_manager = create_game_manager_with_workers()
	
	# Set up first worker with no AP
	game_manager.workers[0].action_points = 0
	
	# Second worker still has AP
	game_manager.workers[1].action_points = 2
	
	return {
		"game_manager": game_manager,
		"exhausted_worker": game_manager.workers[0],
		"active_worker": game_manager.workers[1]
	}

# Test assertion helpers
class TestAssertions:
	static func assert_worker_state(
		worker: Worker,
		expected_position: Vector2i,
		expected_ap: int,
		expected_stones: int
	) -> bool:
		return (
			worker.grid_position == expected_position and
			worker.action_points == expected_ap and
			worker.carried_stones == expected_stones
		)
	
	static func assert_tile_state(
		tile: Tile,
		expected_terrain: Tile.TerrainType,
		expected_has_stone: bool,
		expected_deposit_remaining: int = 0
	) -> bool:
		return (
			tile.terrain_type == expected_terrain and
			tile.has_stone_block == expected_has_stone and
			tile.stone_deposit_remaining == expected_deposit_remaining
		)
	
	static func assert_game_manager_state(
		game_manager: GameManager,
		expected_turn: int,
		expected_worker_index: int,
		expected_pyramid_complete: bool
	) -> bool:
		return (
			game_manager.turn_number == expected_turn and
			game_manager.current_worker_index == expected_worker_index and
			game_manager.pyramid_completed == expected_pyramid_complete
		)

# Grid pattern generators
static func create_grid_pattern_checkerboard(board: GameBoard, size: int = 20) -> void:
	for x in range(size):
		for y in range(size):
			var tile = board.get_tile_at(Vector2i(x, y))
			if tile:
				if (x + y) % 2 == 0:
					tile.terrain_type = Tile.TerrainType.DESERT
				else:
					tile.terrain_type = Tile.TerrainType.WATER

static func create_grid_pattern_borders(board: GameBoard, size: int = 20) -> void:
	for x in range(size):
		for y in range(size):
			var tile = board.get_tile_at(Vector2i(x, y))
			if tile:
				if x == 0 or x == size - 1 or y == 0 or y == size - 1:
					tile.terrain_type = Tile.TerrainType.WATER
				else:
					tile.terrain_type = Tile.TerrainType.DESERT

static func create_grid_pattern_cross(board: GameBoard, size: int = 20) -> void:
	var center = size / 2
	for x in range(size):
		for y in range(size):
			var tile = board.get_tile_at(Vector2i(x, y))
			if tile:
				if x == center or y == center:
					tile.terrain_type = Tile.TerrainType.WATER
				else:
					tile.terrain_type = Tile.TerrainType.DESERT

# Complex scenario builders
static func create_multi_worker_stone_scenario() -> Dictionary:
	var game_manager = create_game_manager_with_workers()
	var board = create_game_board_with_tiles()
	
	# Position workers near different stone deposits
	game_manager.workers[0].grid_position = Vector2i(3, 4)   # Near deposit at (3,5)
	game_manager.workers[1].grid_position = Vector2i(15, 7)  # Near deposit at (15,8)
	
	# Give one worker stones
	game_manager.workers[0].carried_stones = 1
	
	return {
		"game_manager": game_manager,
		"board": board,
		"worker_with_stone": game_manager.workers[0],
		"worker_near_deposit": game_manager.workers[1]
	}

static func create_endgame_scenario() -> Dictionary:
	var scenario = create_pyramid_completion_scenario()
	
	# Leave one tile unfilled
	var board = scenario["board"]
	var last_tile = board.get_tile_at(Vector2i(11, 11))
	if last_tile:
		last_tile.has_stone_block = false
	
	# Position worker with stone at the unfilled tile
	var game_manager = scenario["game_manager"]
	game_manager.workers[0].grid_position = Vector2i(11, 11)
	game_manager.workers[0].carried_stones = 1
	
	return {
		"game_manager": game_manager,
		"board": board,
		"final_tile": last_tile,
		"worker_with_stone": game_manager.workers[0]
	}

# Resource cleanup helpers
static func cleanup_scenario(scenario: Dictionary) -> void:
	for key in scenario.keys():
		var obj = scenario[key]
		if obj is Node:
			obj.queue_free()
		elif obj is RefCounted:
			# RefCounted objects are automatically cleaned up
			pass

static func cleanup_workers(workers: Array) -> void:
	for worker in workers:
		if worker is Worker:
			worker.queue_free()

static func cleanup_tiles(tiles: Array) -> void:
	for tile in tiles:
		if tile is Tile:
			tile.queue_free()

# Performance test data generators
static func create_large_worker_array(count: int = 100) -> Array[Worker]:
	var workers: Array[Worker] = []
	for i in range(count):
		var worker = create_worker(Vector2i(i % 20, i / 20))
		workers.append(worker)
	return workers

static func create_stress_test_scenario(grid_size: int = 50) -> Dictionary:
	var board = GameBoard.new()
	board.GRID_SIZE = grid_size
	board._initialize_grid()
	
	var game_manager = create_game_manager_with_workers()
	
	return {
		"board": board,
		"game_manager": game_manager,
		"grid_size": grid_size
	}

# Random data generators for property-based testing
static func create_random_worker(rng: RandomNumberGenerator = null) -> Worker:
	if not rng:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	
	var position = Vector2i(rng.randi_range(0, 19), rng.randi_range(0, 19))
	var ap = rng.randi_range(0, 2)
	var stones = rng.randi_range(0, 1)
	
	return create_worker(position, ap, stones)

static func create_random_tile(rng: RandomNumberGenerator = null) -> Tile:
	if not rng:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	
	var position = Vector2i(rng.randi_range(0, 19), rng.randi_range(0, 19))
	var terrain_type = rng.randi_range(0, 3) as Tile.TerrainType
	var has_stone = rng.randf() > 0.5
	var deposit_remaining = rng.randi_range(0, 5) if terrain_type == Tile.TerrainType.STONE_DEPOSIT else 0
	
	return create_tile(position, terrain_type, has_stone, deposit_remaining)