extends GdUnitTestSuite

# Worker Foundation Tests
# Tests basic worker actions, state management, and movement logic

var worker: Worker

func before_test():
	worker = Worker.new()
	worker.grid_position = Vector2i(5, 5)
	worker.action_points = 2
	worker.carried_stones = 0

func after_test():
	if worker:
		worker.queue_free()

# Test initialization and default values
func test_worker_initialization():
	var fresh_worker = Worker.new()
	
	# Default values
	assert_int(fresh_worker.action_points).is_equal(2)
	assert_int(fresh_worker.max_action_points).is_equal(2)
	assert_int(fresh_worker.carried_stones).is_equal(0)
	assert_int(fresh_worker.max_stones).is_equal(1)
	assert_bool(fresh_worker.is_selected).is_false()
	
	fresh_worker.queue_free()

# Test action point management
func test_action_point_consumption():
	worker.action_points = 2
	
	# Perform action that consumes 1 AP
	worker.action_points -= 1
	assert_int(worker.action_points).is_equal(1)
	
	# Perform another action
	worker.action_points -= 1
	assert_int(worker.action_points).is_equal(0)

func test_reset_action_points():
	worker.action_points = 0
	worker.reset_action_points()
	assert_int(worker.action_points).is_equal(worker.max_action_points)

# Test movement validation
func test_can_move_to_adjacent():
	worker.grid_position = Vector2i(5, 5)
	worker.action_points = 1
	
	# Valid adjacent moves
	assert_bool(worker.can_move_to(Vector2i(5, 4))).is_true()  # Up
	assert_bool(worker.can_move_to(Vector2i(5, 6))).is_true()  # Down
	assert_bool(worker.can_move_to(Vector2i(4, 5))).is_true()  # Left
	assert_bool(worker.can_move_to(Vector2i(6, 5))).is_true()  # Right

func test_cannot_move_to_non_adjacent():
	worker.grid_position = Vector2i(5, 5)
	worker.action_points = 1
	
	# Invalid moves (not adjacent)
	assert_bool(worker.can_move_to(Vector2i(5, 3))).is_false()  # Too far up
	assert_bool(worker.can_move_to(Vector2i(5, 7))).is_false()  # Too far down
	assert_bool(worker.can_move_to(Vector2i(3, 5))).is_false()  # Too far left
	assert_bool(worker.can_move_to(Vector2i(7, 5))).is_false()  # Too far right
	assert_bool(worker.can_move_to(Vector2i(6, 6))).is_false()  # Diagonal

func test_cannot_move_without_action_points():
	worker.grid_position = Vector2i(5, 5)
	worker.action_points = 0
	
	# Cannot move without AP
	assert_bool(worker.can_move_to(Vector2i(5, 4))).is_false()
	assert_bool(worker.can_move_to(Vector2i(5, 6))).is_false()

# Test movement execution
func test_move_to_success():
	worker.grid_position = Vector2i(5, 5)
	worker.action_points = 2
	
	var target = Vector2i(5, 4)
	var success = worker.move_to(target)
	
	assert_bool(success).is_true()
	assert_vector2i(worker.grid_position).is_equal(target)
	assert_int(worker.action_points).is_equal(1)

func test_move_to_failure():
	worker.grid_position = Vector2i(5, 5)
	worker.action_points = 0
	
	var target = Vector2i(5, 4)
	var initial_position = worker.grid_position
	var success = worker.move_to(target)
	
	assert_bool(success).is_false()
	assert_vector2i(worker.grid_position).is_equal(initial_position)
	assert_int(worker.action_points).is_equal(0)

# Test stone quarrying
func test_can_quarry():
	worker.action_points = 1
	worker.carried_stones = 0
	assert_bool(worker.can_quarry()).is_true()

func test_cannot_quarry_without_action_points():
	worker.action_points = 0
	worker.carried_stones = 0
	assert_bool(worker.can_quarry()).is_false()

func test_cannot_quarry_when_carrying_max_stones():
	worker.action_points = 1
	worker.carried_stones = worker.max_stones
	assert_bool(worker.can_quarry()).is_false()

func test_quarry_stone_success():
	worker.action_points = 2
	worker.carried_stones = 0
	
	var success = worker.quarry_stone()
	
	assert_bool(success).is_true()
	assert_int(worker.carried_stones).is_equal(1)
	assert_int(worker.action_points).is_equal(1)

func test_quarry_stone_failure():
	worker.action_points = 0
	worker.carried_stones = 0
	
	var success = worker.quarry_stone()
	
	assert_bool(success).is_false()
	assert_int(worker.carried_stones).is_equal(0)
	assert_int(worker.action_points).is_equal(0)

# Test stone placement
func test_can_place_stone():
	worker.action_points = 1
	worker.carried_stones = 1
	assert_bool(worker.can_place_stone()).is_true()

func test_cannot_place_stone_without_action_points():
	worker.action_points = 0
	worker.carried_stones = 1
	assert_bool(worker.can_place_stone()).is_false()

func test_cannot_place_stone_without_stones():
	worker.action_points = 1
	worker.carried_stones = 0
	assert_bool(worker.can_place_stone()).is_false()

func test_place_stone_success():
	worker.action_points = 2
	worker.carried_stones = 1
	
	var success = worker.place_stone()
	
	assert_bool(success).is_true()
	assert_int(worker.carried_stones).is_equal(0)
	assert_int(worker.action_points).is_equal(1)

func test_place_stone_failure():
	worker.action_points = 0
	worker.carried_stones = 0
	
	var success = worker.place_stone()
	
	assert_bool(success).is_false()
	assert_int(worker.carried_stones).is_equal(0)
	assert_int(worker.action_points).is_equal(0)

# Test selection state
func test_set_selected():
	worker.is_selected = false
	worker.set_selected(true)
	assert_bool(worker.is_selected).is_true()
	
	worker.set_selected(false)
	assert_bool(worker.is_selected).is_false()

# Test adjacent position calculation
func test_get_adjacent_positions():
	worker.grid_position = Vector2i(5, 5)
	var adjacent = worker.get_adjacent_positions()
	
	assert_int(adjacent.size()).is_equal(4)
	assert_array(adjacent).contains([Vector2i(5, 4)])  # Up
	assert_array(adjacent).contains([Vector2i(5, 6)])  # Down
	assert_array(adjacent).contains([Vector2i(4, 5)])  # Left
	assert_array(adjacent).contains([Vector2i(6, 5)])  # Right

func test_get_adjacent_positions_at_origin():
	worker.grid_position = Vector2i(0, 0)
	var adjacent = worker.get_adjacent_positions()
	
	assert_int(adjacent.size()).is_equal(4)
	assert_array(adjacent).contains([Vector2i(0, -1)])  # Up
	assert_array(adjacent).contains([Vector2i(0, 1)])   # Down
	assert_array(adjacent).contains([Vector2i(-1, 0)])  # Left
	assert_array(adjacent).contains([Vector2i(1, 0)])   # Right

# Test constants
func test_worker_constants():
	assert_int(Worker.TILE_SIZE).is_equal(32)

# Test stone carrying capacity
func test_stone_carrying_limits():
	worker.max_stones = 1
	worker.carried_stones = 0
	
	# Can carry up to max
	assert_bool(worker.can_quarry()).is_true()
	
	worker.carried_stones = 1
	assert_bool(worker.can_quarry()).is_false()

# Test action point limits
func test_action_point_limits():
	worker.max_action_points = 2
	
	# Reset should set to max
	worker.action_points = 0
	worker.reset_action_points()
	assert_int(worker.action_points).is_equal(2)
	
	# Cannot exceed max (if manually set)
	worker.action_points = 5
	worker.reset_action_points()
	assert_int(worker.action_points).is_equal(2)

# Test complete action sequences
func test_complete_quarry_sequence():
	worker.action_points = 2
	worker.carried_stones = 0
	
	# First quarry
	assert_bool(worker.can_quarry()).is_true()
	var success = worker.quarry_stone()
	assert_bool(success).is_true()
	assert_int(worker.carried_stones).is_equal(1)
	assert_int(worker.action_points).is_equal(1)
	
	# Cannot quarry again (at max capacity)
	assert_bool(worker.can_quarry()).is_false()

func test_complete_place_sequence():
	worker.action_points = 2
	worker.carried_stones = 1
	
	# First placement
	assert_bool(worker.can_place_stone()).is_true()
	var success = worker.place_stone()
	assert_bool(success).is_true()
	assert_int(worker.carried_stones).is_equal(0)
	assert_int(worker.action_points).is_equal(1)
	
	# Cannot place again (no stones)
	assert_bool(worker.can_place_stone()).is_false()

func test_complete_movement_sequence():
	worker.grid_position = Vector2i(5, 5)
	worker.action_points = 2
	
	# First move
	var success = worker.move_to(Vector2i(5, 4))
	assert_bool(success).is_true()
	assert_vector2i(worker.grid_position).is_equal(Vector2i(5, 4))
	assert_int(worker.action_points).is_equal(1)
	
	# Second move
	success = worker.move_to(Vector2i(5, 3))
	assert_bool(success).is_true()
	assert_vector2i(worker.grid_position).is_equal(Vector2i(5, 3))
	assert_int(worker.action_points).is_equal(0)
	
	# Cannot move again (no AP)
	assert_bool(worker.can_move_to(Vector2i(5, 2))).is_false()

# Test signal emissions
func test_worker_selected_signal():
	var signal_emitted = false
	var emitted_worker = null
	
	worker.worker_selected.connect(func(w): signal_emitted = true; emitted_worker = w)
	
	# This would normally be called by input handling
	worker.worker_selected.emit(worker)
	
	assert_bool(signal_emitted).is_true()
	assert_object(emitted_worker).is_equal(worker)

func test_worker_moved_signal():
	var signal_emitted = false
	var emitted_worker = null
	var emitted_position = Vector2i(-1, -1)
	
	worker.worker_moved.connect(func(w, pos): signal_emitted = true; emitted_worker = w; emitted_position = pos)
	
	var target_pos = Vector2i(5, 4)
	worker.move_to(target_pos)
	
	assert_bool(signal_emitted).is_true()
	assert_object(emitted_worker).is_equal(worker)
	assert_vector2i(emitted_position).is_equal(target_pos)

func test_action_performed_signal():
	var signal_emitted = false
	var emitted_worker = null
	var emitted_action = ""
	
	worker.action_performed.connect(func(w, action): signal_emitted = true; emitted_worker = w; emitted_action = action)
	
	worker.quarry_stone()
	
	assert_bool(signal_emitted).is_true()
	assert_object(emitted_worker).is_equal(worker)
	assert_str(emitted_action).is_equal("quarry")

# Test edge cases
func test_movement_distance_calculation():
	worker.grid_position = Vector2i(5, 5)
	
	# Test Manhattan distance calculation
	var distance_up = abs(Vector2i(5, 4).x - worker.grid_position.x) + abs(Vector2i(5, 4).y - worker.grid_position.y)
	assert_int(distance_up).is_equal(1)
	
	var distance_diagonal = abs(Vector2i(6, 4).x - worker.grid_position.x) + abs(Vector2i(6, 4).y - worker.grid_position.y)
	assert_int(distance_diagonal).is_equal(2)

func test_negative_action_points():
	worker.action_points = -1
	
	# Should not be able to perform actions with negative AP
	assert_bool(worker.can_move_to(Vector2i(5, 4))).is_false()
	assert_bool(worker.can_quarry()).is_false()
	assert_bool(worker.can_place_stone()).is_false()

func test_negative_carried_stones():
	worker.carried_stones = -1
	worker.action_points = 1
	
	# Should not be able to place stones with negative count
	assert_bool(worker.can_place_stone()).is_false()
	
	# Should still be able to quarry
	assert_bool(worker.can_quarry()).is_true()

# Test state consistency
func test_state_consistency_after_actions():
	worker.action_points = 2
	worker.carried_stones = 0
	
	# Perform quarry
	worker.quarry_stone()
	assert_int(worker.action_points).is_equal(1)
	assert_int(worker.carried_stones).is_equal(1)
	
	# Perform place
	worker.place_stone()
	assert_int(worker.action_points).is_equal(0)
	assert_int(worker.carried_stones).is_equal(0)
	
	# Reset turn
	worker.reset_action_points()
	assert_int(worker.action_points).is_equal(2)
	assert_int(worker.carried_stones).is_equal(0)  # Stones should remain unchanged