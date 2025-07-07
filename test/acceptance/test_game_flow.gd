extends GutTest

var game_manager: GameManager
var game_board: Node2D

func before_each():
	# Set up complete game system
	game_manager = GameManager
	
	# Reset GameManager state for clean tests
	game_manager.workers.clear()
	game_manager.current_worker_index = 0
	game_manager.turn_number = 1
	game_manager.pyramid_completed = false
	game_manager.game_board = null
	
	# Create and initialize game board
	game_board = Node2D.new()
	game_board.set_script(preload("res://scripts/GameBoard.gd"))
	add_child_autofree(game_board)
	
	# Add required child nodes
	var tile_container = Node2D.new()
	tile_container.name = "TileContainer"
	game_board.add_child(tile_container)
	
	var worker_container = Node2D.new()
	worker_container.name = "WorkerContainer"
	game_board.add_child(worker_container)
	
	var highlight_overlay = Node2D.new()
	highlight_overlay.name = "HighlightOverlay"
	game_board.add_child(highlight_overlay)
	
	# Initialize the @onready variables manually
	game_board.tile_container = tile_container
	game_board.worker_container = worker_container  
	game_board.highlight_overlay = highlight_overlay
	
	# Initialize the game
	game_board._initialize_grid()
	game_board._generate_map()
	game_manager.register_game_board(game_board)
	
	# Add workers at starting positions
	_add_worker_at_position(Vector2i(2, 10))   # Worker 1
	_add_worker_at_position(Vector2i(18, 10))  # Worker 2

func _add_worker_at_position(pos: Vector2i) -> Worker:
	var worker = Worker.new()
	worker.grid_position = pos
	add_child_autofree(worker)
	game_manager.add_worker(worker)
	return worker

func test_game_starts_with_correct_initial_state():
	# Verify game starts correctly
	assert_eq(game_manager.workers.size(), 2)
	assert_eq(game_manager.turn_number, 1)
	assert_eq(game_manager.current_worker_index, 0)
	assert_false(game_manager.pyramid_completed)
	
	# Verify workers start with full action points
	for worker in game_manager.workers:
		assert_eq(worker.action_points, 2)
		assert_eq(worker.carried_stones, 0)

func test_map_has_required_elements():
	# Verify map has all required elements
	
	# 1. Pyramid base (3x3 center area)
	for x in range(9, 12):
		for y in range(9, 12):
			var tile = game_board.get_tile_at(Vector2i(x, y))
			assert_eq(tile.terrain_type, Tile.TerrainType.PYRAMID_BASE)
	
	# 2. Water (Nile river at x=6,7)
	for y in range(20):
		var water_tile1 = game_board.get_tile_at(Vector2i(6, y))
		var water_tile2 = game_board.get_tile_at(Vector2i(7, y))
		assert_eq(water_tile1.terrain_type, Tile.TerrainType.WATER)
		assert_eq(water_tile2.terrain_type, Tile.TerrainType.WATER)
	
	# 3. Stone deposits at specific locations
	var stone_positions = [Vector2i(3, 5), Vector2i(15, 8), Vector2i(12, 16)]
	for pos in stone_positions:
		var tile = game_board.get_tile_at(pos)
		assert_eq(tile.terrain_type, Tile.TerrainType.STONE_DEPOSIT)
		assert_eq(tile.stone_deposit_remaining, 5)

func test_worker_can_perform_basic_actions():
	var worker = game_manager.get_current_worker()
	var initial_ap = worker.action_points
	
	# Test movement
	var move_result = worker.move_to(Vector2i(3, 10))
	assert_true(move_result)
	assert_eq(worker.action_points, initial_ap - 1)
	
	# Reset for next test
	worker.action_points = 2
	worker.grid_position = Vector2i(2, 5)  # Adjacent to stone deposit
	
	# Test quarrying
	var deposit_tile = game_board.get_tile_at(Vector2i(3, 5))
	var initial_deposit = deposit_tile.stone_deposit_remaining
	
	var quarry_result = worker.quarry_stone()
	deposit_tile.quarry_stone()
	
	assert_true(quarry_result)
	assert_eq(worker.carried_stones, 1)
	assert_eq(deposit_tile.stone_deposit_remaining, initial_deposit - 1)

func test_turn_progression_works_correctly():
	watch_signals(game_manager)
	
	var worker1 = game_manager.workers[0]
	var worker2 = game_manager.workers[1]
	var initial_turn = game_manager.turn_number
	
	# Exhaust first worker's action points
	worker1.action_points = 1
	worker1.move_to(Vector2i(3, 10))
	assert_eq(worker1.action_points, 0)
	
	# End first worker's turn
	game_manager.end_current_worker_turn()
	assert_eq(game_manager.current_worker_index, 1)
	
	# Exhaust second worker's action points
	worker2.action_points = 1
	worker2.move_to(Vector2i(17, 10))
	assert_eq(worker2.action_points, 0)
	
	# End second worker's turn - should start new turn
	game_manager.end_current_worker_turn()
	
	assert_eq(game_manager.turn_number, initial_turn + 1)
	assert_signal_emitted(game_manager, "turn_changed")
	
	# Both workers should have reset action points
	assert_eq(worker1.action_points, 2)
	assert_eq(worker2.action_points, 2)

func test_pyramid_building_workflow():
	# Test complete workflow from quarrying to pyramid completion
	
	var worker = game_manager.workers[0]
	
	# 1. Move worker to stone deposit
	worker.grid_position = Vector2i(2, 5)
	worker.action_points = 2
	
	# 2. Quarry stones
	var deposit_tile = game_board.get_tile_at(Vector2i(3, 5))
	worker.quarry_stone()
	deposit_tile.quarry_stone()
	
	assert_eq(worker.carried_stones, 1)
	
	# 3. Move to pyramid base (simulate pathfinding)
	worker.grid_position = Vector2i(9, 9)  # Corner of pyramid
	worker.action_points = 2
	
	# 4. Place stone
	var pyramid_tile = game_board.get_tile_at(Vector2i(9, 9))
	worker.place_stone()
	pyramid_tile.place_stone()
	
	assert_eq(worker.carried_stones, 0)
	assert_true(pyramid_tile.has_stone_block)

func test_victory_condition():
	watch_signals(game_manager)
	
	# Fill entire pyramid base
	for x in range(9, 12):
		for y in range(9, 12):
			var tile = game_board.get_tile_at(Vector2i(x, y))
			tile.has_stone_block = true
	
	# Trigger victory check
	game_manager._check_pyramid_completion()
	
	assert_true(game_manager.pyramid_completed)
	assert_signal_emitted(game_manager, "game_won")

func test_resource_management():
	# Test that resources are properly managed throughout the game
	
	var total_initial_stones = 0
	var stone_positions = [Vector2i(3, 5), Vector2i(15, 8), Vector2i(12, 16)]
	
	# Count initial stones
	for pos in stone_positions:
		var tile = game_board.get_tile_at(pos)
		total_initial_stones += tile.stone_deposit_remaining
	
	assert_eq(total_initial_stones, 15)  # 3 deposits × 5 stones each
	
	# Test stone depletion
	var deposit_tile = game_board.get_tile_at(Vector2i(3, 5))
	var initial_stones = deposit_tile.stone_deposit_remaining
	
	# Deplete one stone
	deposit_tile.quarry_stone()
	assert_eq(deposit_tile.stone_deposit_remaining, initial_stones - 1)

func test_game_constraints():
	# Test various game constraints and rules
	
	var worker = game_manager.workers[0]
	
	# 1. Worker cannot carry more than max stones
	worker.carried_stones = worker.max_stones
	var quarry_result = worker.quarry_stone()
	assert_false(quarry_result)
	
	# 2. Worker cannot act without action points
	worker.action_points = 0
	var move_result = worker.move_to(Vector2i(3, 10))
	assert_false(move_result)
	
	# 3. Cannot move through water
	worker.grid_position = Vector2i(5, 10)
	worker.action_points = 2
	var water_move = worker.move_to(Vector2i(6, 10))  # Water tile
	assert_false(water_move)
	
	# 4. Cannot place stone on water
	var water_tile = game_board.get_tile_at(Vector2i(6, 10))
	assert_false(water_tile.can_place_stone())

func test_complete_game_scenario():
	# Test a complete mini-game scenario
	
	var worker1 = game_manager.workers[0]
	var worker2 = game_manager.workers[1]
	
	# Turn 1: Move workers toward resources
	worker1.grid_position = Vector2i(2, 10)
	worker1.move_to(Vector2i(2, 9))
	worker1.move_to(Vector2i(2, 8))
	assert_eq(worker1.action_points, 0)
	
	game_manager._next_worker()
	
	worker2.grid_position = Vector2i(18, 10)
	worker2.move_to(Vector2i(17, 10))
	worker2.move_to(Vector2i(16, 10))
	assert_eq(worker2.action_points, 0)
	
	# Start new turn
	game_manager._start_new_turn()
	assert_eq(game_manager.turn_number, 2)
	assert_eq(worker1.action_points, 2)
	assert_eq(worker2.action_points, 2)
	
	# Turn 2: Continue toward deposits
	worker1.move_to(Vector2i(2, 7))
	worker1.move_to(Vector2i(2, 6))
	
	game_manager._next_worker()
	
	worker2.move_to(Vector2i(15, 10))
	worker2.move_to(Vector2i(15, 9))
	
	# The game continues...
	assert_eq(game_manager.turn_number, 2)
	assert_true(game_manager.workers.size() > 0)

func test_pyramid_progress_tracking():
	# Test pyramid completion progress
	
	assert_eq(game_manager.get_pyramid_progress(), 0.0)
	
	# Fill 3 out of 9 pyramid tiles
	var positions = [Vector2i(9, 9), Vector2i(9, 10), Vector2i(9, 11)]
	for pos in positions:
		var tile = game_board.get_tile_at(pos)
		tile.has_stone_block = true
	
	var progress = game_manager.get_pyramid_progress()
	assert_almost_eq(progress, 3.0/9.0, 0.01)
	
	# Fill all remaining tiles
	for x in range(9, 12):
		for y in range(9, 12):
			var tile = game_board.get_tile_at(Vector2i(x, y))
			tile.has_stone_block = true
	
	progress = game_manager.get_pyramid_progress()
	assert_almost_eq(progress, 1.0, 0.01)
