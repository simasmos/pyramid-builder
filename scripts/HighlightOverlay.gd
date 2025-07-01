extends Node2D

const GRID_SIZE = 20
const TILE_SIZE = 32

var highlighted_tiles: Dictionary = {}

func _draw():
	for pos in highlighted_tiles:
		var color = highlighted_tiles[pos]
		var world_pos = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
		var rect = Rect2(world_pos, Vector2(TILE_SIZE, TILE_SIZE))
		draw_rect(rect, color, false, 3.0)

func set_highlight(grid_pos: Vector2i, enabled: bool, color: Color = Color.WHITE):
	if enabled:
		highlighted_tiles[grid_pos] = color
	else:
		highlighted_tiles.erase(grid_pos)
	queue_redraw()

func clear_all_highlights():
	highlighted_tiles.clear()
	queue_redraw()