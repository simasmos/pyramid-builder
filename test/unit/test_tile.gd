extends GutTest

var tile: Tile

func before_each():
	tile = Tile.new()
	add_child_autofree(tile)
	tile.grid_position = Vector2i(5, 5)

func test_tile_initializes_with_correct_defaults():
	var new_tile = Tile.new()
	assert_eq(new_tile.terrain_type, Tile.TerrainType.DESERT)
	assert_false(new_tile.has_stone_block)
	assert_eq(new_tile.stone_deposit_remaining, 0)
	assert_false(new_tile.is_highlighted)

func test_world_to_grid_conversion():
	var world_pos = Vector2(160, 96)  # 5*32, 3*32
	var grid_pos = tile.world_to_grid(world_pos)
	assert_eq(grid_pos, Vector2i(5, 3))

func test_grid_to_world_conversion():
	var grid_pos = Vector2i(5, 3)
	var world_pos = tile.grid_to_world(grid_pos)
	assert_eq(world_pos, Vector2(5 * 32 + 16, 3 * 32 + 16))

func test_desert_tile_can_move_through():
	tile.terrain_type = Tile.TerrainType.DESERT
	assert_true(tile.can_move_through())

func test_water_tile_cannot_move_through():
	tile.terrain_type = Tile.TerrainType.WATER
	assert_false(tile.can_move_through())

func test_stone_deposit_tile_cannot_move_through():
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	assert_false(tile.can_move_through())

func test_pyramid_base_tile_can_move_through():
	tile.terrain_type = Tile.TerrainType.PYRAMID_BASE
	assert_true(tile.can_move_through())

func test_stone_deposit_can_quarry_with_stones():
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	tile.stone_deposit_remaining = 5
	assert_true(tile.can_quarry())

func test_stone_deposit_cannot_quarry_without_stones():
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	tile.stone_deposit_remaining = 0
	assert_false(tile.can_quarry())

func test_non_stone_deposit_cannot_quarry():
	tile.terrain_type = Tile.TerrainType.DESERT
	tile.stone_deposit_remaining = 5
	assert_false(tile.can_quarry())

func test_desert_tile_can_place_stone():
	tile.terrain_type = Tile.TerrainType.DESERT
	tile.has_stone_block = false
	assert_true(tile.can_place_stone())

func test_pyramid_base_tile_can_place_stone():
	tile.terrain_type = Tile.TerrainType.PYRAMID_BASE
	tile.has_stone_block = false
	assert_true(tile.can_place_stone())

func test_water_tile_cannot_place_stone():
	tile.terrain_type = Tile.TerrainType.WATER
	assert_false(tile.can_place_stone())

func test_stone_deposit_tile_cannot_place_stone():
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	assert_false(tile.can_place_stone())

func test_tile_with_stone_block_cannot_place_stone():
	tile.terrain_type = Tile.TerrainType.DESERT
	tile.has_stone_block = true
	assert_false(tile.can_place_stone())

func test_quarry_stone_reduces_deposit():
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	tile.stone_deposit_remaining = 5
	
	var result = tile.quarry_stone()
	
	assert_true(result)
	assert_eq(tile.stone_deposit_remaining, 4)

func test_quarry_stone_converts_to_desert_when_empty():
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	tile.stone_deposit_remaining = 1
	
	tile.quarry_stone()
	
	assert_eq(tile.terrain_type, Tile.TerrainType.DESERT)
	assert_eq(tile.stone_deposit_remaining, 0)

func test_quarry_stone_fails_when_cannot_quarry():
	tile.terrain_type = Tile.TerrainType.DESERT
	
	var result = tile.quarry_stone()
	
	assert_false(result)

func test_place_stone_sets_stone_block():
	tile.terrain_type = Tile.TerrainType.DESERT
	tile.has_stone_block = false
	
	var result = tile.place_stone()
	
	assert_true(result)
	assert_true(tile.has_stone_block)

func test_place_stone_fails_when_cannot_place():
	tile.terrain_type = Tile.TerrainType.WATER
	
	var result = tile.place_stone()
	
	assert_false(result)
	assert_false(tile.has_stone_block)

# Test terrain type passability
func test_terrain_type_passability(params=use_parameters([
	[Tile.TerrainType.DESERT, true],
	[Tile.TerrainType.WATER, false],
	[Tile.TerrainType.STONE_DEPOSIT, false],
	[Tile.TerrainType.PYRAMID_BASE, true]
])):
	var terrain = params[0]
	var expected_passable = params[1]
	
	tile.terrain_type = terrain
	assert_eq(tile.can_move_through(), expected_passable)

# Test stone placement by terrain type
func test_stone_placement_by_terrain(params=use_parameters([
	[Tile.TerrainType.DESERT, true],
	[Tile.TerrainType.WATER, false],
	[Tile.TerrainType.STONE_DEPOSIT, false],
	[Tile.TerrainType.PYRAMID_BASE, true]
])):
	var terrain = params[0]
	var expected_placeable = params[1]
	
	tile.terrain_type = terrain
	tile.has_stone_block = false
	assert_eq(tile.can_place_stone(), expected_placeable)

# Test quarrying behavior
func test_quarrying_behavior(params=use_parameters([
	[5, 4],  # 5 stones -> 4 after quarry
	[1, 0],  # 1 stone -> 0 after quarry
	[0, 0]   # 0 stones -> cannot quarry
])):
	var initial_stones = params[0]
	var expected_stones = params[1]
	
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	tile.stone_deposit_remaining = initial_stones
	
	var result = tile.quarry_stone()
	
	if initial_stones > 0:
		assert_true(result)
		assert_eq(tile.stone_deposit_remaining, expected_stones)
	else:
		assert_false(result)

func test_coordinate_conversions_are_inverse():
	# Test that converting back and forth preserves the original values
	var original_grid = Vector2i(10, 15)
	var world_pos = tile.grid_to_world(original_grid)
	var converted_back = tile.world_to_grid(world_pos)
	
	assert_eq(converted_back, original_grid)

func test_tile_visual_setup_called_on_ready():
	# This is more of an integration test but verifies the tile initializes properly
	var new_tile = Tile.new()
	add_child_autofree(new_tile)
	new_tile.terrain_type = Tile.TerrainType.DESERT
	new_tile._ready()
	
	# Check that it has a sprite child
	assert_gt(new_tile.get_child_count(), 0)

func test_stone_deposit_shows_remaining_count():
	tile.terrain_type = Tile.TerrainType.STONE_DEPOSIT
	tile.stone_deposit_remaining = 3
	tile._setup_visuals()
	
	# Should have a label showing the count
	var has_label = false
	for child in tile.get_children():
		if child is Label:
			has_label = true
			assert_eq(child.text, "3")
			break
	
	assert_true(has_label, "Stone deposit should have a label showing remaining count")