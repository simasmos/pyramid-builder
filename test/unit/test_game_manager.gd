extends GutTest

var game_manager: GameManager
var mock_worker1: Worker
var mock_worker2: Worker

func before_each():
	# Use the singleton GameManager instead of creating new instance
	game_manager = GameManager
	
	# Reset GameManager state for clean tests
	game_manager.workers.clear()
	game_manager.current_worker_index = 0
	game_manager.turn_number = 1
	game_manager.pyramid_completed = false
	game_manager.game_board = null
	
	# Create mock workers
	mock_worker1 = Worker.new()
	mock_worker2 = Worker.new()
	add_child_autofree(mock_worker1)
	add_child_autofree(mock_worker2)
	
	# Set up initial positions
	mock_worker1.grid_position = Vector2i(2, 10)
	mock_worker2.grid_position = Vector2i(18, 10)

func test_game_manager_initializes_with_correct_defaults():
	assert_eq(game_manager.workers.size(), 0)
	assert_eq(game_manager.current_worker_index, 0)
	assert_eq(game_manager.turn_number, 1)
	assert_false(game_manager.pyramid_completed)

func test_add_worker_increases_worker_count():
	var initial_count = game_manager.workers.size()
	game_manager.add_worker(mock_worker1)
	assert_eq(game_manager.workers.size(), initial_count + 1)

func test_add_worker_connects_signals():
	watch_signals(game_manager)
	game_manager.add_worker(mock_worker1)
	
	# Trigger worker selection to test signal connection
	mock_worker1.worker_selected.emit(mock_worker1)
	
	assert_signal_emitted(game_manager, "worker_changed")

func test_get_current_worker_returns_first_worker():
	game_manager.add_worker(mock_worker1)
	game_manager.add_worker(mock_worker2)
	
	var current_worker = game_manager.get_current_worker()
	assert_eq(current_worker, mock_worker1)

func test_get_current_worker_returns_null_when_no_workers():
	var current_worker = game_manager.get_current_worker()
	assert_null(current_worker)

func test_worker_selection_updates_current_index():
	game_manager.add_worker(mock_worker1)
	game_manager.add_worker(mock_worker2)
	
	# Select second worker
	game_manager._on_worker_selected(mock_worker2)
	
	assert_eq(game_manager.current_worker_index, 1)
	assert_eq(game_manager.get_current_worker(), mock_worker2)

func test_end_turn_resets_action_points_for_all_workers():
	game_manager.add_worker(mock_worker1)
	game_manager.add_worker(mock_worker2)
	
	mock_worker1.action_points = 2
	mock_worker2.action_points = 1
	
	var initial_turn = game_manager.turn_number
	
	game_manager.end_turn()
	
	assert_eq(game_manager.turn_number, initial_turn + 1)
	assert_eq(mock_worker1.action_points, 2)
	assert_eq(mock_worker2.action_points, 2)

func test_next_worker_cycles_through_workers():
	game_manager.add_worker(mock_worker1)
	game_manager.add_worker(mock_worker2)
	
	assert_eq(game_manager.current_worker_index, 0)
	
	game_manager._next_worker()
	assert_eq(game_manager.current_worker_index, 1)
	
	game_manager._next_worker()
	assert_eq(game_manager.current_worker_index, 0)

func test_new_turn_increments_turn_number():
	var initial_turn = game_manager.turn_number
	game_manager._start_new_turn()
	assert_eq(game_manager.turn_number, initial_turn + 1)

func test_new_turn_resets_worker_action_points():
	game_manager.add_worker(mock_worker1)
	game_manager.add_worker(mock_worker2)
	
	# Deplete action points
	mock_worker1.action_points = 0
	mock_worker2.action_points = 0
	
	game_manager._start_new_turn()
	
	assert_eq(mock_worker1.action_points, mock_worker1.max_action_points)
	assert_eq(mock_worker2.action_points, mock_worker2.max_action_points)

func test_new_turn_emits_turn_changed_signal():
	watch_signals(game_manager)
	game_manager._start_new_turn()
	assert_signal_emitted(game_manager, "turn_changed")

func test_can_worker_act_returns_true_with_action_points():
	game_manager.add_worker(mock_worker1)
	mock_worker1.action_points = 1
	
	assert_true(game_manager.can_worker_act())

func test_can_worker_act_returns_false_without_action_points():
	game_manager.add_worker(mock_worker1)
	mock_worker1.action_points = 0
	
	assert_false(game_manager.can_worker_act())

func test_can_worker_act_returns_false_without_current_worker():
	assert_false(game_manager.can_worker_act())

func test_is_position_valid_returns_true_for_valid_positions():
	assert_true(game_manager.is_position_valid(Vector2i(0, 0)))
	assert_true(game_manager.is_position_valid(Vector2i(19, 19)))
	assert_true(game_manager.is_position_valid(Vector2i(10, 10)))

func test_is_position_valid_returns_false_for_invalid_positions():
	assert_false(game_manager.is_position_valid(Vector2i(-1, 0)))
	assert_false(game_manager.is_position_valid(Vector2i(20, 0)))
	assert_false(game_manager.is_position_valid(Vector2i(0, -1)))
	assert_false(game_manager.is_position_valid(Vector2i(0, 20)))

func test_get_worker_at_position_returns_correct_worker():
	game_manager.add_worker(mock_worker1)
	game_manager.add_worker(mock_worker2)
	
	var worker_at_pos = game_manager.get_worker_at_position(Vector2i(2, 10))
	assert_eq(worker_at_pos, mock_worker1)
	
	worker_at_pos = game_manager.get_worker_at_position(Vector2i(18, 10))
	assert_eq(worker_at_pos, mock_worker2)

func test_get_worker_at_position_returns_null_for_empty_position():
	game_manager.add_worker(mock_worker1)
	
	var worker_at_pos = game_manager.get_worker_at_position(Vector2i(5, 5))
	assert_null(worker_at_pos)

func test_action_performed_emits_worker_changed_signal():
	watch_signals(game_manager)
	game_manager.add_worker(mock_worker1)
	
	game_manager._on_worker_action_performed(mock_worker1, "move")
	
	assert_signal_emitted(game_manager, "worker_changed")

func test_pyramid_progress_returns_zero_without_game_board():
	var progress = game_manager.get_pyramid_progress()
	assert_eq(progress, 0.0)

# Test class for pyramid completion (requires mock game board)
class TestPyramidCompletion:
	extends GutTest
	
	var game_manager: GameManager
	var mock_game_board: Node2D
	var mock_tiles: Array[Tile]
	
	func before_each():
		game_manager = GameManager
		
		# Create mock game board
		mock_game_board = Node2D.new()
		add_child_autofree(mock_game_board)
		game_manager.register_game_board(mock_game_board)
		
		# Create mock tiles for pyramid area
		mock_tiles = []
		for x in range(9, 12):
			for y in range(9, 12):
				var tile = Tile.new()
				tile.grid_position = Vector2i(x, y)
				tile.terrain_type = Tile.TerrainType.PYRAMID_BASE
				mock_tiles.append(tile)
		
		# Add get_tile_at method to mock game board
		mock_game_board.set_script(preload("res://test/unit/mock_game_board.gd"))
		mock_game_board.set_mock_tiles(mock_tiles)
	
	func test_pyramid_completion_detected_when_all_tiles_filled():
		watch_signals(game_manager)
		
		# Fill all pyramid tiles
		for tile in mock_tiles:
			tile.has_stone_block = true
		
		game_manager._check_pyramid_completion()
		
		assert_true(game_manager.pyramid_completed)
		assert_signal_emitted(game_manager, "game_won")
	
	func test_pyramid_completion_not_detected_when_partially_filled():
		# Fill only some pyramid tiles
		for i in range(5):
			mock_tiles[i].has_stone_block = true
		
		game_manager._check_pyramid_completion()
		
		assert_false(game_manager.pyramid_completed)
	
	func test_pyramid_progress_calculates_correctly():
		# Fill 6 out of 9 tiles
		for i in range(6):
			mock_tiles[i].has_stone_block = true
		
		var progress = game_manager.get_pyramid_progress()
		assert_almost_eq(progress, 6.0/9.0, 0.01)
