extends GutTest

var worker: Worker

func before_each():
	worker = Worker.new()
	add_child_autofree(worker)
	worker.grid_position = Vector2i(5, 5)
	worker.action_points = 2
	# Initialize worker properly (call _ready equivalent)
	worker._setup_visuals()
	worker._update_position()

func test_worker_initializes_with_correct_defaults():
	var new_worker = Worker.new()
	assert_eq(new_worker.action_points, 2)
	assert_eq(new_worker.max_action_points, 2)
	assert_eq(new_worker.carried_stones, 0)
	assert_eq(new_worker.max_stones, 1)
	assert_false(new_worker.is_selected)

func test_worker_position_updates_correctly():
	worker.grid_position = Vector2i(10, 15)
	worker._update_position()
	
	var expected_pos = Vector2(10 * 32 + 16, 15 * 32 + 16)
	assert_eq(worker.position, expected_pos)

func test_set_selected_updates_selection_state():
	worker.set_selected(true)
	assert_true(worker.is_selected)
	
	worker.set_selected(false)
	assert_false(worker.is_selected)

func test_can_move_to_adjacent_position():
	assert_true(worker.can_move_to(Vector2i(6, 5)))  # Right
	assert_true(worker.can_move_to(Vector2i(4, 5)))  # Left
	assert_true(worker.can_move_to(Vector2i(5, 6)))  # Down
	assert_true(worker.can_move_to(Vector2i(5, 4)))  # Up

func test_cannot_move_to_non_adjacent_position():
	assert_false(worker.can_move_to(Vector2i(7, 5)))  # Two tiles away
	assert_false(worker.can_move_to(Vector2i(6, 6)))  # Diagonal

func test_cannot_move_without_action_points():
	worker.action_points = 0
	assert_false(worker.can_move_to(Vector2i(6, 5)))

func test_move_to_updates_position_and_action_points():
	var target_pos = Vector2i(6, 5)
	var result = worker.move_to(target_pos)
	
	assert_true(result)
	assert_eq(worker.grid_position, target_pos)
	assert_eq(worker.action_points, 1)

func test_move_to_emits_signals():
	watch_signals(worker)
	
	worker.move_to(Vector2i(6, 5))
	
	assert_signal_emitted(worker, "worker_moved")
	assert_signal_emitted(worker, "action_performed")

func test_move_to_fails_for_invalid_position():
	var result = worker.move_to(Vector2i(7, 5))  # Too far
	
	assert_false(result)
	assert_eq(worker.grid_position, Vector2i(5, 5))  # Unchanged
	assert_eq(worker.action_points, 2)  # Unchanged

func test_can_quarry_with_action_points_and_space():
	assert_true(worker.can_quarry())

func test_cannot_quarry_without_action_points():
	worker.action_points = 0
	assert_false(worker.can_quarry())

func test_cannot_quarry_when_carrying_max_stones():
	worker.carried_stones = worker.max_stones
	assert_false(worker.can_quarry())

func test_quarry_stone_increases_carried_stones():
	var initial_stones = worker.carried_stones
	var result = worker.quarry_stone()
	
	assert_true(result)
	assert_eq(worker.carried_stones, initial_stones + 1)
	assert_eq(worker.action_points, 1)

func test_quarry_stone_emits_action_performed_signal():
	watch_signals(worker)
	
	worker.quarry_stone()
	
	assert_signal_emitted(worker, "action_performed")

func test_quarry_stone_fails_when_cannot_quarry():
	worker.action_points = 0
	var result = worker.quarry_stone()
	
	assert_false(result)
	assert_eq(worker.carried_stones, 0)

func test_can_place_stone_with_action_points_and_stones():
	worker.carried_stones = 1
	assert_true(worker.can_place_stone())

func test_cannot_place_stone_without_action_points():
	worker.carried_stones = 1
	worker.action_points = 0
	assert_false(worker.can_place_stone())

func test_cannot_place_stone_without_stones():
	worker.carried_stones = 0
	assert_false(worker.can_place_stone())

func test_place_stone_decreases_carried_stones():
	worker.carried_stones = 1
	var result = worker.place_stone()
	
	assert_true(result)
	assert_eq(worker.carried_stones, 0)
	assert_eq(worker.action_points, 1)

func test_place_stone_emits_action_performed_signal():
	worker.carried_stones = 1
	watch_signals(worker)
	
	worker.place_stone()
	
	assert_signal_emitted(worker, "action_performed")

func test_place_stone_fails_when_cannot_place():
	worker.carried_stones = 0
	var result = worker.place_stone()
	
	assert_false(result)
	assert_eq(worker.action_points, 2)

func test_reset_action_points_restores_max_action_points():
	worker.action_points = 0
	worker.reset_action_points()
	assert_eq(worker.action_points, worker.max_action_points)

func test_get_adjacent_positions_returns_four_positions():
	var adjacent = worker.get_adjacent_positions()
	assert_eq(adjacent.size(), 4)
	
	var expected_positions = [
		Vector2i(5, 4),  # Up
		Vector2i(5, 6),  # Down
		Vector2i(4, 5),  # Left
		Vector2i(6, 5)   # Right
	]
	
	for pos in expected_positions:
		assert_true(adjacent.has(pos))

# Test parameterized movement in all directions
func test_movement_in_all_directions(params=use_parameters([
	[Vector2i(1, 0), "right"],
	[Vector2i(-1, 0), "left"], 
	[Vector2i(0, 1), "down"],
	[Vector2i(0, -1), "up"]
])):
	var direction = params[0]
	var direction_name = params[1]
	
	worker.grid_position = Vector2i(10, 10)  # Center position
	var target_pos = worker.grid_position + direction
	
	var result = worker.move_to(target_pos)
	
	assert_true(result, "Should be able to move " + direction_name)
	assert_eq(worker.grid_position, target_pos)
	assert_eq(worker.action_points, 1)

# Test action point costs
func test_action_costs(params=use_parameters([
	["move", 1],
	["quarry", 1],
	["place", 1]
])):
	var action = params[0]
	var expected_cost = params[1]
	
	worker.action_points = 2
	worker.carried_stones = 1  # Needed for place action
	
	match action:
		"move":
			worker.move_to(Vector2i(6, 5))
		"quarry":
			worker.quarry_stone()
		"place":
			worker.place_stone()
	
	assert_eq(worker.action_points, 2 - expected_cost)

func test_input_event_emits_worker_selected_signal():
	watch_signals(worker)
	
	# Create a mock input event
	var input_event = InputEventMouseButton.new()
	input_event.pressed = true
	input_event.button_index = MOUSE_BUTTON_LEFT
	
	worker._input_event(null, input_event, 0)
	
	assert_signal_emitted(worker, "worker_selected")
