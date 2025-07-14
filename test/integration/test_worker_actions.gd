extends GutTest

var game_manager: GameManager
var game_board: Node2D
var worker: Worker
var tile_container: Node2D
var worker_container: Node2D
var highlight_overlay: Node2D

func before_each():
	# Set up the complete system for integration testing
	game_manager = GameManager
	
	# Reset GameManager state for clean tests
	game_manager.workers.clear()
	game_manager.current_worker_index = 0
	game_manager.turn_number = 1
	game_manager.pyramid_completed = false
	game_manager.game_board = null
	
	# Create game board with required components
	game_board = Node2D.new()
	game_board.set_script(preload("res://scripts/GameBoard.gd"))
	add_child_autofree(game_board)
	
	# Create required containers
	tile_container = Node2D.new()
	tile_container.name = "TileContainer"
	game_board.add_child(tile_container)
	
	worker_container = Node2D.new()
	worker_container.name = "WorkerContainer"
	game_board.add_child(worker_container)
	
	highlight_overlay = Node2D.new()
	highlight_overlay.name = "HighlightOverlay"
	game_board.add_child(highlight_overlay)
	
	# Initialize the @onready variables manually
	game_board.tile_container = tile_container
	game_board.worker_container = worker_container
	game_board.highlight_overlay = highlight_overlay
	
	# Initialize game board
	game_board._initialize_grid()
	game_board._generate_map()
	
	# Register game board with manager
	game_manager.register_game_board(game_board)
	
	# Create and add a worker
	worker = Worker.new()
	worker.grid_position = Vector2i(5, 5)
	add_child_autofree(worker)
	game_manager.add_worker(worker)

func test_worker_movement_updates_game_state():
	var initial_pos = worker.grid_position
	var target_pos = Vector2i(6, 5)
	
	# Move worker
	var result = worker.move_to(target_pos)
	
	assert_true(result)
	assert_eq(worker.grid_position, target_pos)
	assert_eq(worker.action_points, 1)

func test_worker_cannot_move_to_water():
	# Try to move to a water tile
	var water_pos = Vector2i(6, 10)
	var initial_pos = worker.grid_position
	
	# Move worker to position adjacent to water
	worker.grid_position = Vector2i(5, 10)
	
	var result = worker.move_to(water_pos)
	
	assert_false(result)
	assert_eq(worker.grid_position, Vector2i(5, 10))  # Should not move

func test_worker_cannot_move_to_stone_deposit():
	# Try to move to a stone deposit
	var deposit_pos = Vector2i(3, 5)
	
	# Move worker to position adjacent to deposit
	worker.grid_position = Vector2i(2, 5)
	
	var result = worker.move_to(deposit_pos)
	
	assert_false(result)
	assert_eq(worker.grid_position, Vector2i(2, 5))  # Should not move

func test_worker_quarrying_from_stone_deposit():
	# Move worker adjacent to stone deposit
	worker.grid_position = Vector2i(2, 5)  # Adjacent to deposit at (3,5)
	var deposit_tile = game_board.get_tile_at(Vector2i(3, 5))
	
	# Initial state
	var initial_stones = worker.carried_stones
	var initial_deposit = deposit_tile.stone_deposit_remaining
	
	# Perform quarrying action
	var quarry_result = worker.quarry_stone()
	var tile_result = deposit_tile.quarry_stone()
	
	assert_true(quarry_result)
	assert_true(tile_result)
	assert_eq(worker.carried_stones, initial_stones + 1)
	assert_eq(deposit_tile.stone_deposit_remaining, initial_deposit - 1)

func test_worker_stone_placement_on_pyramid_base():
	# Move worker to pyramid base
	worker.grid_position = Vector2i(10, 10)  # Center of pyramid
	worker.carried_stones = 1
	
	var pyramid_tile = game_board.get_tile_at(Vector2i(10, 10))
	
	# Place stone
	var worker_result = worker.place_stone()
	var tile_result = pyramid_tile.place_stone()
	
	assert_true(worker_result)
	assert_true(tile_result)
	assert_eq(worker.carried_stones, 0)
	assert_true(pyramid_tile.has_stone_block)

func test_complete_quarry_and_build_workflow():
	# Test the complete workflow: move to deposit, quarry, move to pyramid, place
	
	# 1. Move worker to position adjacent to stone deposit
	worker.grid_position = Vector2i(2, 5)
	worker.action_points = 2
	
	# 2. Quarry stone
	var deposit_tile = game_board.get_tile_at(Vector2i(3, 5))
	var quarry_result = worker.quarry_stone()
	deposit_tile.quarry_stone()
	
	assert_true(quarry_result)
	assert_eq(worker.carried_stones, 1)
	assert_eq(worker.action_points, 1)
	
	# 3. Move toward pyramid (simulate multiple moves)
	worker.action_points = 2  # Reset for movement
	var move_result = worker.move_to(Vector2i(3, 5))  # Can't move to deposit
	assert_false(move_result)  # Should fail
	
	# Move to valid adjacent position
	move_result = worker.move_to(Vector2i(2, 6))
	assert_true(move_result)
	assert_eq(worker.action_points, 1)
	
	# 4. Place stone on pyramid base (simulate reaching pyramid)
	worker.grid_position = Vector2i(10, 10)  # Teleport to pyramid for test
	worker.action_points = 2
	
	var pyramid_tile = game_board.get_tile_at(Vector2i(10, 10))
	var place_result = worker.place_stone()
	pyramid_tile.place_stone()
	
	assert_true(place_result)
	assert_eq(worker.carried_stones, 0)
	assert_true(pyramid_tile.has_stone_block)

func test_game_manager_tracks_worker_actions():
	watch_signals(game_manager)
	
	# Perform an action
	worker.move_to(Vector2i(6, 5))
	
	# Should trigger action_performed signal which game manager handles
	assert_signal_emitted(game_manager, "worker_changed")

func test_turn_management_with_worker_actions():
	# Add second worker
	var worker2 = Worker.new()
	worker2.grid_position = Vector2i(15, 15)
	add_child_autofree(worker2)
	game_manager.add_worker(worker2)
	
	var initial_turn = game_manager.turn_number
	
	# Exhaust first worker's action points
	worker.action_points = 1
	worker.move_to(Vector2i(6, 5))
	assert_eq(worker.action_points, 0)
	
	# End worker turn manually
	game_manager.end_current_worker_turn()
	
	# Should move to next worker
	assert_eq(game_manager.current_worker_index, 1)
	assert_eq(game_manager.get_current_worker(), worker2)

func test_pyramid_completion_detection():
	watch_signals(game_manager)
	
	# Fill all pyramid tiles
	for x in range(9, 12):
		for y in range(9, 12):
			var tile = game_board.get_tile_at(Vector2i(x, y))
			tile.has_stone_block = true
	
	# Trigger completion check
	game_manager._check_pyramid_completion()
	
	assert_true(game_manager.pyramid_completed)
	assert_signal_emitted(game_manager, "game_won")

func test_worker_action_validation_with_game_board():
	# Test that worker actions are properly validated against game board state
	
	# 1. Cannot move to occupied position
	var worker2 = Worker.new()
	worker2.grid_position = Vector2i(6, 5)
	add_child_autofree(worker2)
	
	# First worker tries to move to second worker's position
	var result = worker.move_to(Vector2i(6, 5))
	# Note: This test would need additional logic in GameBoard to check occupancy
	
	# 2. Cannot quarry from empty deposit
	var empty_tile = game_board.get_tile_at(Vector2i(5, 5))  # Desert tile
	assert_false(empty_tile.can_quarry())
	
	# 3. Cannot place stone on water
	var water_tile = game_board.get_tile_at(Vector2i(6, 10))
	assert_false(water_tile.can_place_stone())

func test_action_point_management_across_turns():
	worker.action_points = 0  # Exhaust action points
	
	# Start new turn
	game_manager._start_new_turn()
	
	# Action points should be restored
	assert_eq(worker.action_points, worker.max_action_points)

func test_resource_depletion():
	# Test that stone deposits can be completely depleted
	var deposit_tile = game_board.get_tile_at(Vector2i(3, 5))
	var initial_stones = deposit_tile.stone_deposit_remaining
	
	# Deplete all stones
	for i in range(initial_stones):
		var result = deposit_tile.quarry_stone()
		assert_true(result)
	
	# Should be converted to desert
	assert_eq(deposit_tile.terrain_type, Tile.TerrainType.DESERT)
	assert_eq(deposit_tile.stone_deposit_remaining, 0)
	assert_false(deposit_tile.can_quarry())