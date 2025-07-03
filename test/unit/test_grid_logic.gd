extends GdUnitTestSuite

# Grid Logic Foundation Tests
# Tests coordinate system, grid validation, and position utilities

var game_board: GameBoard

func before_test():
	game_board = GameBoard.new()
	# Don't call _ready() to avoid scene dependencies
	game_board._initialize_grid()

func after_test():
	if game_board:
		game_board.queue_free()

# Test grid initialization
func test_grid_initialization():
	assert_int(game_board.tiles.size()).is_equal(20)
	
	# Check all rows are properly initialized
	for x in range(20):
		assert_int(game_board.tiles[x].size()).is_equal(20)

# Test coordinate conversion
func test_world_to_grid_conversion():
	# Test center of tiles
	var world_pos = Vector2(96, 128)  # 3*32, 4*32
	var grid_pos = game_board.world_to_grid(world_pos)
	assert_vector2i(grid_pos).is_equal(Vector2i(3, 4))
	
	# Test origin
	world_pos = Vector2(0, 0)
	grid_pos = game_board.world_to_grid(world_pos)
	assert_vector2i(grid_pos).is_equal(Vector2i(0, 0))
	
	# Test boundary
	world_pos = Vector2(31, 31)
	grid_pos = game_board.world_to_grid(world_pos)
	assert_vector2i(grid_pos).is_equal(Vector2i(0, 0))
	
	# Test edge case at tile boundary
	world_pos = Vector2(32, 32)
	grid_pos = game_board.world_to_grid(world_pos)
	assert_vector2i(grid_pos).is_equal(Vector2i(1, 1))

func test_grid_to_world_conversion():
	# Test center positioning
	var grid_pos = Vector2i(3, 4)
	var world_pos = game_board.grid_to_world(grid_pos)
	assert_vector2(world_pos).is_equal(Vector2(112, 144))  # 3*32+16, 4*32+16
	
	# Test origin
	grid_pos = Vector2i(0, 0)
	world_pos = game_board.grid_to_world(grid_pos)
	assert_vector2(world_pos).is_equal(Vector2(16, 16))
	
	# Test max grid position
	grid_pos = Vector2i(19, 19)
	world_pos = game_board.grid_to_world(grid_pos)
	assert_vector2(world_pos).is_equal(Vector2(624, 624))  # 19*32+16, 19*32+16

func test_coordinate_conversion_round_trip():
	# Test grid->world->grid conversion maintains integrity
	var original_grid = Vector2i(7, 12)
	var world_pos = game_board.grid_to_world(original_grid)
	var converted_back = game_board.world_to_grid(world_pos)
	assert_vector2i(converted_back).is_equal(original_grid)
	
	# Test multiple positions
	var test_positions = [
		Vector2i(0, 0),
		Vector2i(10, 10),
		Vector2i(19, 19),
		Vector2i(5, 15),
		Vector2i(15, 5)
	]
	
	for pos in test_positions:
		var world = game_board.grid_to_world(pos)
		var back_to_grid = game_board.world_to_grid(world)
		assert_vector2i(back_to_grid).is_equal(pos)

# Test position validation
func test_is_valid_position():
	# Valid positions
	assert_bool(game_board.is_valid_position(Vector2i(0, 0))).is_true()
	assert_bool(game_board.is_valid_position(Vector2i(10, 10))).is_true()
	assert_bool(game_board.is_valid_position(Vector2i(19, 19))).is_true()
	assert_bool(game_board.is_valid_position(Vector2i(0, 19))).is_true()
	assert_bool(game_board.is_valid_position(Vector2i(19, 0))).is_true()

func test_invalid_positions():
	# Invalid positions
	assert_bool(game_board.is_valid_position(Vector2i(-1, 0))).is_false()
	assert_bool(game_board.is_valid_position(Vector2i(0, -1))).is_false()
	assert_bool(game_board.is_valid_position(Vector2i(20, 10))).is_false()
	assert_bool(game_board.is_valid_position(Vector2i(10, 20))).is_false()
	assert_bool(game_board.is_valid_position(Vector2i(-1, -1))).is_false()
	assert_bool(game_board.is_valid_position(Vector2i(20, 20))).is_false()

# Test terrain type mapping
func test_terrain_type_mapping():
	# Test pyramid base area (3x3 center)
	for x in range(9, 12):
		for y in range(9, 12):
			var terrain = game_board._get_terrain_type(Vector2i(x, y))
			assert_int(terrain).is_equal(Tile.TerrainType.PYRAMID_BASE)

func test_water_terrain_mapping():
	# Test Nile river (vertical strip at x=6,7)
	for x in range(6, 8):
		for y in range(20):
			var terrain = game_board._get_terrain_type(Vector2i(x, y))
			assert_int(terrain).is_equal(Tile.TerrainType.WATER)

func test_stone_deposit_mapping():
	# Test predefined stone deposit locations
	var stone_positions = [
		Vector2i(3, 5),
		Vector2i(15, 8),
		Vector2i(12, 16)
	]
	
	for pos in stone_positions:
		var terrain = game_board._get_terrain_type(pos)
		assert_int(terrain).is_equal(Tile.TerrainType.STONE_DEPOSIT)

func test_desert_terrain_mapping():
	# Test non-special positions are desert
	var desert_positions = [
		Vector2i(0, 0),
		Vector2i(5, 5),
		Vector2i(19, 19),
		Vector2i(1, 1)
	]
	
	for pos in desert_positions:
		var terrain = game_board._get_terrain_type(pos)
		assert_int(terrain).is_equal(Tile.TerrainType.DESERT)

# Test constants
func test_grid_constants():
	assert_int(game_board.GRID_SIZE).is_equal(20)
	assert_int(game_board.TILE_SIZE).is_equal(32)
	assert_vector2i(game_board.PYRAMID_CENTER).is_equal(Vector2i(10, 10))

# Test grid boundaries
func test_grid_boundaries():
	# Test all four corners
	assert_bool(game_board.is_valid_position(Vector2i(0, 0))).is_true()
	assert_bool(game_board.is_valid_position(Vector2i(0, 19))).is_true()
	assert_bool(game_board.is_valid_position(Vector2i(19, 0))).is_true()
	assert_bool(game_board.is_valid_position(Vector2i(19, 19))).is_true()
	
	# Test just outside boundaries
	assert_bool(game_board.is_valid_position(Vector2i(-1, 0))).is_false()
	assert_bool(game_board.is_valid_position(Vector2i(0, -1))).is_false()
	assert_bool(game_board.is_valid_position(Vector2i(20, 19))).is_false()
	assert_bool(game_board.is_valid_position(Vector2i(19, 20))).is_false()

# Test tile access
func test_get_tile_at_valid_position():
	# After full initialization, tiles should exist
	game_board._generate_map()
	
	var tile = game_board.get_tile_at(Vector2i(5, 5))
	assert_object(tile).is_not_null()
	assert_vector2i(tile.grid_position).is_equal(Vector2i(5, 5))

func test_get_tile_at_invalid_position():
	game_board._generate_map()
	
	# Invalid positions should return null
	var tile = game_board.get_tile_at(Vector2i(-1, 0))
	assert_object(tile).is_null()
	
	tile = game_board.get_tile_at(Vector2i(20, 10))
	assert_object(tile).is_null()

# Test adjacency calculations
func test_adjacent_position_calculations():
	# Test center position
	var center = Vector2i(10, 10)
	var expected_adjacent = [
		Vector2i(10, 9),   # Up
		Vector2i(10, 11),  # Down
		Vector2i(9, 10),   # Left
		Vector2i(11, 10)   # Right
	]
	
	# Mock worker to test adjacency
	var worker = Worker.new()
	worker.grid_position = center
	var adjacent = worker.get_adjacent_positions()
	
	assert_int(adjacent.size()).is_equal(4)
	for pos in expected_adjacent:
		assert_array(adjacent).contains([pos])
	
	worker.queue_free()

func test_adjacent_positions_at_boundaries():
	# Test corner position
	var corner = Vector2i(0, 0)
	var worker = Worker.new()
	worker.grid_position = corner
	var adjacent = worker.get_adjacent_positions()
	
	# Should still return 4 positions (some invalid)
	assert_int(adjacent.size()).is_equal(4)
	
	# Check which ones are valid
	var valid_adjacent = []
	for pos in adjacent:
		if game_board.is_valid_position(pos):
			valid_adjacent.append(pos)
	
	assert_int(valid_adjacent.size()).is_equal(2)  # Only right and down are valid
	assert_array(valid_adjacent).contains([Vector2i(1, 0)])  # Right
	assert_array(valid_adjacent).contains([Vector2i(0, 1)])  # Down
	
	worker.queue_free()

# Test distance calculations
func test_manhattan_distance():
	# Test horizontal distance
	var pos1 = Vector2i(5, 5)
	var pos2 = Vector2i(8, 5)
	var distance = abs(pos2.x - pos1.x) + abs(pos2.y - pos1.y)
	assert_int(distance).is_equal(3)
	
	# Test vertical distance
	pos1 = Vector2i(5, 5)
	pos2 = Vector2i(5, 8)
	distance = abs(pos2.x - pos1.x) + abs(pos2.y - pos1.y)
	assert_int(distance).is_equal(3)
	
	# Test diagonal distance
	pos1 = Vector2i(5, 5)
	pos2 = Vector2i(8, 8)
	distance = abs(pos2.x - pos1.x) + abs(pos2.y - pos1.y)
	assert_int(distance).is_equal(6)
	
	# Test adjacent distance
	pos1 = Vector2i(5, 5)
	pos2 = Vector2i(5, 6)
	distance = abs(pos2.x - pos1.x) + abs(pos2.y - pos1.y)
	assert_int(distance).is_equal(1)

# Test special area detection
func test_pyramid_area_detection():
	# Test all pyramid positions
	var pyramid_positions = []
	for x in range(9, 12):
		for y in range(9, 12):
			pyramid_positions.append(Vector2i(x, y))
	
	assert_int(pyramid_positions.size()).is_equal(9)
	
	# All should be pyramid base terrain
	for pos in pyramid_positions:
		var terrain = game_board._get_terrain_type(pos)
		assert_int(terrain).is_equal(Tile.TerrainType.PYRAMID_BASE)

func test_water_area_detection():
	# Test water strip
	var water_positions = []
	for x in range(6, 8):
		for y in range(20):
			water_positions.append(Vector2i(x, y))
	
	assert_int(water_positions.size()).is_equal(40)  # 2 columns * 20 rows
	
	# All should be water terrain
	for pos in water_positions:
		var terrain = game_board._get_terrain_type(pos)
		assert_int(terrain).is_equal(Tile.TerrainType.WATER)

# Test edge cases
func test_large_coordinates():
	# Test very large coordinates
	var large_pos = Vector2i(1000, 1000)
	assert_bool(game_board.is_valid_position(large_pos)).is_false()
	
	# Test conversion with large world coordinates
	var large_world = Vector2(1000000, 1000000)
	var grid_pos = game_board.world_to_grid(large_world)
	# Should still work, just return a large grid position
	assert_vector2i(grid_pos).is_equal(Vector2i(31250, 31250))

func test_negative_coordinates():
	# Test negative coordinates
	var neg_pos = Vector2i(-5, -10)
	assert_bool(game_board.is_valid_position(neg_pos)).is_false()
	
	# Test conversion with negative world coordinates
	var neg_world = Vector2(-100, -200)
	var grid_pos = game_board.world_to_grid(neg_world)
	assert_vector2i(grid_pos).is_equal(Vector2i(-4, -7))

# Test terrain type consistency
func test_terrain_type_consistency():
	# Test that the same position always returns the same terrain type
	var test_pos = Vector2i(5, 5)
	var terrain1 = game_board._get_terrain_type(test_pos)
	var terrain2 = game_board._get_terrain_type(test_pos)
	assert_int(terrain1).is_equal(terrain2)
	
	# Test special positions
	var pyramid_pos = Vector2i(10, 10)
	var pyramid_terrain = game_board._get_terrain_type(pyramid_pos)
	assert_int(pyramid_terrain).is_equal(Tile.TerrainType.PYRAMID_BASE)
	
	var water_pos = Vector2i(6, 5)
	var water_terrain = game_board._get_terrain_type(water_pos)
	assert_int(water_terrain).is_equal(Tile.TerrainType.WATER)
	
	var stone_pos = Vector2i(3, 5)
	var stone_terrain = game_board._get_terrain_type(stone_pos)
	assert_int(stone_terrain).is_equal(Tile.TerrainType.STONE_DEPOSIT)