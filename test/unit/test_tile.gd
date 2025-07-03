extends GdUnitTestSuite

# Tile Foundation Tests  
# Tests terrain system, coordinate conversion, and stone mechanics

var tile: Tile

func before_test():
	tile = Tile.new()
	tile.grid_position = Vector2i(5, 5)

func after_test():
	if tile:
		tile.queue_free()

# Test terrain type properties
func test_terrain_type_initialization():
	# Default terrain should be desert
	assert_int(tile.terrain_type).is_equal(Tile.TerrainType.DESERT)
	
	# Test setting different terrain types
	tile.terrain_type = Tile.TerrainType.WATER
	assert_int(tile.terrain_type).is_equal(Tile.TerrainType.WATER)
	
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	assert_int(tile.terrain_type).is_equal(Tile.TerrainType.STONE_DEPOSIT)
	
	tile.terrain_type = Tile.TerrainType.PYRAMID_BASE
	assert_int(tile.terrain_type).is_equal(Tile.TerrainType.PYRAMID_BASE)

# Test movement permissions
func test_can_move_through_desert():
	tile.terrain_type = Tile.TerrainType.DESERT
	assert_bool(tile.can_move_through()).is_true()

func test_can_move_through_pyramid_base():
	tile.terrain_type = Tile.TerrainType.PYRAMID_BASE
	assert_bool(tile.can_move_through()).is_true()

func test_cannot_move_through_water():
	tile.terrain_type = Tile.TerrainType.WATER
	assert_bool(tile.can_move_through()).is_false()

func test_cannot_move_through_stone_deposit():
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	assert_bool(tile.can_move_through()).is_false()

# Test stone quarrying
func test_can_quarry_stone_deposit():
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	tile.stone_deposit_remaining = 5
	assert_bool(tile.can_quarry()).is_true()

func test_cannot_quarry_empty_deposit():
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	tile.stone_deposit_remaining = 0
	assert_bool(tile.can_quarry()).is_false()

func test_cannot_quarry_other_terrain():
	tile.terrain_type = Tile.TerrainType.DESERT
	tile.stone_deposit_remaining = 5  # This shouldn't matter
	assert_bool(tile.can_quarry()).is_false()
	
	tile.terrain_type = Tile.TerrainType.WATER
	assert_bool(tile.can_quarry()).is_false()
	
	tile.terrain_type = Tile.TerrainType.PYRAMID_BASE
	assert_bool(tile.can_quarry()).is_false()

# Test stone placement
func test_can_place_stone_on_desert():
	tile.terrain_type = Tile.TerrainType.DESERT
	tile.has_stone_block = false
	assert_bool(tile.can_place_stone()).is_true()

func test_can_place_stone_on_pyramid_base():
	tile.terrain_type = Tile.TerrainType.PYRAMID_BASE
	tile.has_stone_block = false
	assert_bool(tile.can_place_stone()).is_true()

func test_cannot_place_stone_on_water():
	tile.terrain_type = Tile.TerrainType.WATER
	tile.has_stone_block = false
	assert_bool(tile.can_place_stone()).is_false()

func test_cannot_place_stone_on_stone_deposit():
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	tile.has_stone_block = false
	assert_bool(tile.can_place_stone()).is_false()

func test_cannot_place_stone_when_already_has_stone():
	tile.terrain_type = Tile.TerrainType.DESERT
	tile.has_stone_block = true
	assert_bool(tile.can_place_stone()).is_false()
	
	tile.terrain_type = Tile.TerrainType.PYRAMID_BASE
	tile.has_stone_block = true
	assert_bool(tile.can_place_stone()).is_false()

# Test quarry stone action
func test_quarry_stone_success():
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	tile.stone_deposit_remaining = 3
	
	var success = tile.quarry_stone()
	assert_bool(success).is_true()
	assert_int(tile.stone_deposit_remaining).is_equal(2)

func test_quarry_stone_failure():
	tile.terrain_type = Tile.TerrainType.DESERT
	tile.stone_deposit_remaining = 0
	
	var success = tile.quarry_stone()
	assert_bool(success).is_false()
	assert_int(tile.stone_deposit_remaining).is_equal(0)

func test_quarry_stone_depletes_deposit():
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	tile.stone_deposit_remaining = 1
	
	var success = tile.quarry_stone()
	assert_bool(success).is_true()
	assert_int(tile.stone_deposit_remaining).is_equal(0)
	# Should convert to desert when depleted
	assert_int(tile.terrain_type).is_equal(Tile.TerrainType.DESERT)

# Test place stone action
func test_place_stone_success():
	tile.terrain_type = Tile.TerrainType.DESERT
	tile.has_stone_block = false
	
	var success = tile.place_stone()
	assert_bool(success).is_true()
	assert_bool(tile.has_stone_block).is_true()

func test_place_stone_failure():
	tile.terrain_type = Tile.TerrainType.WATER
	tile.has_stone_block = false
	
	var success = tile.place_stone()
	assert_bool(success).is_false()
	assert_bool(tile.has_stone_block).is_false()

func test_place_stone_on_occupied_tile():
	tile.terrain_type = Tile.TerrainType.DESERT
	tile.has_stone_block = true
	
	var success = tile.place_stone()
	assert_bool(success).is_false()
	assert_bool(tile.has_stone_block).is_true()

# Test coordinate conversion
func test_world_to_grid_conversion():
	# Test center of tile
	var world_pos = Vector2(160, 192)  # 5*32, 6*32
	var grid_pos = tile.world_to_grid(world_pos)
	assert_vector2i(grid_pos).is_equal(Vector2i(5, 6))
	
	# Test origin
	world_pos = Vector2(0, 0)
	grid_pos = tile.world_to_grid(world_pos)
	assert_vector2i(grid_pos).is_equal(Vector2i(0, 0))
	
	# Test edge case
	world_pos = Vector2(31, 31)
	grid_pos = tile.world_to_grid(world_pos)
	assert_vector2i(grid_pos).is_equal(Vector2i(0, 0))

func test_grid_to_world_conversion():
	# Test center positioning
	var grid_pos = Vector2i(5, 6)
	var world_pos = tile.grid_to_world(grid_pos)
	assert_vector2(world_pos).is_equal(Vector2(176, 208))  # 5*32+16, 6*32+16
	
	# Test origin
	grid_pos = Vector2i(0, 0)
	world_pos = tile.grid_to_world(grid_pos)
	assert_vector2(world_pos).is_equal(Vector2(16, 16))  # Center of first tile

func test_coordinate_conversion_round_trip():
	# Test that converting back and forth maintains integrity
	var original_grid = Vector2i(10, 15)
	var world_pos = tile.grid_to_world(original_grid)
	var converted_back = tile.world_to_grid(world_pos)
	assert_vector2i(converted_back).is_equal(original_grid)

# Test initial state
func test_initial_state():
	var fresh_tile = Tile.new()
	
	# Default values
	assert_int(fresh_tile.terrain_type).is_equal(Tile.TerrainType.DESERT)
	assert_bool(fresh_tile.has_stone_block).is_false()
	assert_int(fresh_tile.stone_deposit_remaining).is_equal(0)
	assert_bool(fresh_tile.is_highlighted).is_false()
	
	fresh_tile.queue_free()

# Test constants
func test_tile_constants():
	assert_int(Tile.TILE_SIZE).is_equal(32)

# Test stone deposit mechanics
func test_stone_deposit_lifecycle():
	# Create stone deposit with stones
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	tile.stone_deposit_remaining = 3
	
	# First quarry
	assert_bool(tile.can_quarry()).is_true()
	tile.quarry_stone()
	assert_int(tile.stone_deposit_remaining).is_equal(2)
	assert_int(tile.terrain_type).is_equal(Tile.TerrainType.STONE_DEPOSIT)
	
	# Second quarry
	tile.quarry_stone()
	assert_int(tile.stone_deposit_remaining).is_equal(1)
	assert_int(tile.terrain_type).is_equal(Tile.TerrainType.STONE_DEPOSIT)
	
	# Final quarry - should convert to desert
	tile.quarry_stone()
	assert_int(tile.stone_deposit_remaining).is_equal(0)
	assert_int(tile.terrain_type).is_equal(Tile.TerrainType.DESERT)
	assert_bool(tile.can_quarry()).is_false()

# Test terrain type validation
func test_terrain_enum_values():
	# Test all terrain types are properly defined
	assert_int(Tile.TerrainType.DESERT).is_equal(0)
	assert_int(Tile.TerrainType.STONE_DEPOSIT).is_equal(1)
	assert_int(Tile.TerrainType.WATER).is_equal(2)
	assert_int(Tile.TerrainType.PYRAMID_BASE).is_equal(3)

# Test edge cases
func test_negative_stone_deposit():
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	tile.stone_deposit_remaining = -1
	assert_bool(tile.can_quarry()).is_false()

func test_large_stone_deposit():
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	tile.stone_deposit_remaining = 100
	assert_bool(tile.can_quarry()).is_true()
	
	tile.quarry_stone()
	assert_int(tile.stone_deposit_remaining).is_equal(99)

# Test grid position property
func test_grid_position_property():
	var test_pos = Vector2i(12, 8)
	tile.grid_position = test_pos
	assert_vector2i(tile.grid_position).is_equal(test_pos)

# Test stone block state changes
func test_stone_block_state_changes():
	# Start without stone block
	tile.terrain_type = Tile.TerrainType.PYRAMID_BASE
	tile.has_stone_block = false
	
	# Place stone block
	assert_bool(tile.place_stone()).is_true()
	assert_bool(tile.has_stone_block).is_true()
	
	# Should not be able to place another
	assert_bool(tile.can_place_stone()).is_false()
	assert_bool(tile.place_stone()).is_false()
	
	# Manual reset
	tile.has_stone_block = false
	assert_bool(tile.can_place_stone()).is_true()