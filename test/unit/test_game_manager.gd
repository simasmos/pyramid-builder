extends GdUnitTestSuite

# GameManager Foundation Tests
# Tests core game state management, turn progression, and worker management

var game_manager: GameManager
var mock_worker_1: Worker
var mock_worker_2: Worker

func before_test():
	# Create fresh GameManager instance for each test
	game_manager = GameManager.new()
	
	# Create mock workers
	mock_worker_1 = Worker.new()
	mock_worker_1.grid_position = Vector2i(2, 10)
	mock_worker_1.action_points = 2
	
	mock_worker_2 = Worker.new()
	mock_worker_2.grid_position = Vector2i(18, 10)
	mock_worker_2.action_points = 2
	
	# Add workers to game manager
	game_manager.add_worker(mock_worker_1)
	game_manager.add_worker(mock_worker_2)

func after_test():
	# Clean up
	if game_manager:
		game_manager.queue_free()
	if mock_worker_1:
		mock_worker_1.queue_free()
	if mock_worker_2:
		mock_worker_2.queue_free()

# Test worker management
func test_add_worker():
	# Use existing game_manager instance to avoid conflicts
	var initial_worker_count = game_manager.workers.size()
	var worker = Worker.new()
	
	game_manager.add_worker(worker)
	
	assert_int(game_manager.workers.size()).is_equal(initial_worker_count + 1)
	assert_object(game_manager.workers[-1]).is_equal(worker)  # Check last added worker
	
	# Cleanup will be handled by after_test()
	worker.queue_free()

func test_get_current_worker():
	# Test initial state
	var current_worker = game_manager.get_current_worker()
	assert_object(current_worker).is_equal(mock_worker_1)
	
	# Test after changing index
	game_manager.current_worker_index = 1
	current_worker = game_manager.get_current_worker()
	assert_object(current_worker).is_equal(mock_worker_2)

func test_get_current_worker_empty_list():
	# Test with a fresh manager that has no workers
	var empty_manager = GameManager.new()
	var current_worker = empty_manager.get_current_worker()
	assert_object(current_worker).is_null()
	
	# Proper cleanup
	empty_manager.queue_free()

func test_get_current_worker_invalid_index():
	game_manager.current_worker_index = 5  # Out of bounds
	var current_worker = game_manager.get_current_worker()
	assert_object(current_worker).is_null()

# Test turn progression
func test_initial_turn_state():
	assert_int(game_manager.turn_number).is_equal(1)
	assert_int(game_manager.current_worker_index).is_equal(0)
	assert_bool(game_manager.pyramid_completed).is_false()

func test_worker_turn_progression():
	# Start with first worker
	assert_int(game_manager.current_worker_index).is_equal(0)
	
	# End current worker's turn
	game_manager.end_current_worker_turn()
	
	# Should move to next worker
	assert_int(game_manager.current_worker_index).is_equal(1)
	assert_int(mock_worker_1.action_points).is_equal(0)

func test_turn_number_progression():
	var initial_turn = game_manager.turn_number
	
	# Exhaust both workers
	game_manager.end_current_worker_turn()  # Worker 1 -> Worker 2
	game_manager.end_current_worker_turn()  # Worker 2 -> New Turn
	
	# Should start new turn
	assert_int(game_manager.turn_number).is_equal(initial_turn + 1)
	assert_int(game_manager.current_worker_index).is_equal(0)

func test_new_turn_resets_action_points():
	# Exhaust workers' action points
	mock_worker_1.action_points = 0
	mock_worker_2.action_points = 0
	
	# Force new turn
	game_manager._start_new_turn()
	
	# Action points should be reset
	assert_int(mock_worker_1.action_points).is_equal(2)
	assert_int(mock_worker_2.action_points).is_equal(2)

# Test action point management
func test_can_worker_act():
	# Worker with action points can act
	mock_worker_1.action_points = 1
	assert_bool(game_manager.can_worker_act()).is_true()
	
	# Worker without action points cannot act
	mock_worker_1.action_points = 0
	assert_bool(game_manager.can_worker_act()).is_false()

func test_can_worker_act_no_workers():
	var empty_manager = GameManager.new()
	assert_bool(empty_manager.can_worker_act()).is_false()
	empty_manager.queue_free()

# Test position validation
func test_is_position_valid():
	# Valid positions
	assert_bool(game_manager.is_position_valid(Vector2i(0, 0))).is_true()
	assert_bool(game_manager.is_position_valid(Vector2i(10, 10))).is_true()
	assert_bool(game_manager.is_position_valid(Vector2i(19, 19))).is_true()
	
	# Invalid positions
	assert_bool(game_manager.is_position_valid(Vector2i(-1, 0))).is_false()
	assert_bool(game_manager.is_position_valid(Vector2i(0, -1))).is_false()
	assert_bool(game_manager.is_position_valid(Vector2i(20, 10))).is_false()
	assert_bool(game_manager.is_position_valid(Vector2i(10, 20))).is_false()

# Test worker position tracking
func test_get_worker_at_position():
	# Should find worker at known position
	var worker = game_manager.get_worker_at_position(Vector2i(2, 10))
	assert_object(worker).is_equal(mock_worker_1)
	
	# Should find second worker
	worker = game_manager.get_worker_at_position(Vector2i(18, 10))
	assert_object(worker).is_equal(mock_worker_2)
	
	# Should return null for empty position
	worker = game_manager.get_worker_at_position(Vector2i(5, 5))
	assert_object(worker).is_null()

# Test pyramid completion logic
func test_pyramid_completion_detection():
	# Mock game board for pyramid completion test
	var mock_board = MockGameBoard.new()
	game_manager.register_game_board(mock_board)
	
	# Initially no pyramid completion
	assert_bool(game_manager.pyramid_completed).is_false()
	
	# Fill pyramid area
	mock_board.fill_pyramid_area()
	
	# Trigger completion check
	game_manager._check_pyramid_completion()
	
	# Should detect completion
	assert_bool(game_manager.pyramid_completed).is_true()
	
	mock_board.queue_free()

func test_pyramid_progress_calculation():
	var mock_board = MockGameBoard.new()
	game_manager.register_game_board(mock_board)
	
	# Initially 0% progress
	var progress = game_manager.get_pyramid_progress()
	assert_float(progress).is_equal(0.0)
	
	# Fill half the pyramid
	mock_board.fill_pyramid_tiles(4)
	progress = game_manager.get_pyramid_progress()
	assert_float(progress).is_between(0.4, 0.5)
	
	# Fill complete pyramid
	mock_board.fill_pyramid_area()
	progress = game_manager.get_pyramid_progress()
	assert_float(progress).is_equal(1.0)
	
	mock_board.queue_free()

# Test signal emissions
func test_worker_changed_signal():
	var signal_emitted = false
	game_manager.worker_changed.connect(func(): signal_emitted = true)
	
	# Change worker should emit signal
	game_manager._on_worker_selected(mock_worker_2)
	assert_bool(signal_emitted).is_true()

func test_turn_changed_signal():
	var signal_emitted = false
	game_manager.turn_changed.connect(func(): signal_emitted = true)
	
	# Starting new turn should emit signal
	game_manager._start_new_turn()
	assert_bool(signal_emitted).is_true()

func test_game_won_signal():
	var signal_emitted = false
	game_manager.game_won.connect(func(): signal_emitted = true)
	
	var mock_board = MockGameBoard.new()
	game_manager.register_game_board(mock_board)
	mock_board.fill_pyramid_area()
	
	# Completion should emit game won signal
	game_manager._check_pyramid_completion()
	assert_bool(signal_emitted).is_true()
	
	mock_board.queue_free()

# Test constants
func test_game_constants():
	assert_int(game_manager.GRID_SIZE).is_equal(20)
	assert_vector2i(game_manager.PYRAMID_CENTER).is_equal(Vector2i(10, 10))

# Mock GameBoard class for testing
class MockGameBoard extends Node2D:
	var tiles: Dictionary = {}
	var filled_tiles: int = 0
	
	func get_tile_at(pos: Vector2i) -> MockTile:
		if not tiles.has(pos):
			tiles[pos] = MockTile.new()
		return tiles[pos]
	
	func fill_pyramid_area():
		for x in range(9, 12):
			for y in range(9, 12):
				var tile = get_tile_at(Vector2i(x, y))
				tile.has_stone_block = true
		filled_tiles = 9
	
	func fill_pyramid_tiles(count: int):
		filled_tiles = 0
		for x in range(9, 12):
			for y in range(9, 12):
				if filled_tiles >= count:
					break
				var tile = get_tile_at(Vector2i(x, y))
				tile.has_stone_block = true
				filled_tiles += 1

# Mock Tile class for testing
class MockTile extends Node2D:
	var has_stone_block: bool = false