extends Node2D

const GRID_SIZE = 20
const TILE_SIZE = 32

func _draw():
	# Draw visible border lines between tiles
	var border_color = Color(0.0, 0.0, 0.0, 0.8)  # Dark and visible
	
	# Vertical lines
	for x in range(GRID_SIZE + 1):
		var start_pos = Vector2(x * TILE_SIZE, 0)
		var end_pos = Vector2(x * TILE_SIZE, GRID_SIZE * TILE_SIZE)
		draw_line(start_pos, end_pos, border_color, 1.0)
	
	# Horizontal lines
	for y in range(GRID_SIZE + 1):
		var start_pos = Vector2(0, y * TILE_SIZE)
		var end_pos = Vector2(GRID_SIZE * TILE_SIZE, y * TILE_SIZE)
		draw_line(start_pos, end_pos, border_color, 1.0)