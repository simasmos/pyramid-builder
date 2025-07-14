extends Node2D

var mock_tiles: Array[Tile] = []

func set_mock_tiles(tiles: Array[Tile]):
	mock_tiles = tiles

func get_tile_at(pos: Vector2i) -> Tile:
	for tile in mock_tiles:
		if tile.grid_position == pos:
			return tile
	return null
