class_name Tile
extends Node2D

enum TerrainType {
	DESERT,
	STONE_DEPOSIT,
	WATER,
	PYRAMID_BASE
}

@export var terrain_type: TerrainType = TerrainType.DESERT
@export var grid_position: Vector2i
@export var has_stone_block: bool = false
@export var stone_deposit_remaining: int = 0

const TILE_SIZE = 32
var is_highlighted: bool = false
var highlight_color: Color = Color.WHITE

func _ready():
	_setup_visuals()

func _setup_visuals():
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	var sprite = Sprite2D.new()
	add_child(sprite)
	
	# Create a simple colored rectangle for now
	var texture = ImageTexture.new()
	var image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGB8)
	
	# If tile has a stone block, make it grey
	if has_stone_block:
		image.fill(Color(0.7, 0.7, 0.7))  # Grey stone block
	else:
		match terrain_type:
			TerrainType.DESERT:
				image.fill(Color(0.85, 0.7, 0.4))  # Sandy color
			TerrainType.STONE_DEPOSIT:
				image.fill(Color(0.5, 0.5, 0.5))   # Gray stone
			TerrainType.WATER:
				image.fill(Color(0.2, 0.5, 0.8))   # Blue water
			TerrainType.PYRAMID_BASE:
				image.fill(Color(0.6, 0.4, 0.2))   # Brown stone
	
	texture.set_image(image)
	sprite.texture = texture
	
	# Add stone deposit indicator
	if terrain_type == TerrainType.STONE_DEPOSIT and stone_deposit_remaining > 0:
		var label = Label.new()
		label.text = str(stone_deposit_remaining)
		label.position = Vector2(4, 4)
		label.add_theme_font_size_override("font_size", 12)
		add_child(label)

func _draw():
	pass

func set_highlight(enabled: bool, color: Color = Color.WHITE):
	# Highlights are now handled by HighlightOverlay
	pass

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE/2, grid_pos.y * TILE_SIZE + TILE_SIZE/2)

func can_move_through() -> bool:
	return terrain_type != TerrainType.WATER and terrain_type != TerrainType.STONE_DEPOSIT

func can_quarry() -> bool:
	return terrain_type == TerrainType.STONE_DEPOSIT and stone_deposit_remaining > 0

func can_place_stone() -> bool:
	return (terrain_type == TerrainType.DESERT or terrain_type == TerrainType.PYRAMID_BASE) and not has_stone_block

func quarry_stone() -> bool:
	if can_quarry():
		_play_quarry_animation()
		stone_deposit_remaining -= 1
		if stone_deposit_remaining == 0:
			terrain_type = TerrainType.DESERT
			_setup_visuals()
		else:
			_setup_visuals()  # Update label with new count
		return true
	return false

func _play_quarry_animation():
	# Create a simple shake animation
	var tween = create_tween()
	var original_pos = position
	
	# Shake effect
	tween.tween_method(_shake_position, 0.0, 1.0, 0.3)
	tween.tween_callback(_reset_position.bind(original_pos))

func _shake_position(progress: float):
	if progress < 1.0:
		var shake_intensity = 3.0 * (1.0 - progress)
		position.x += randf_range(-shake_intensity, shake_intensity)
		position.y += randf_range(-shake_intensity, shake_intensity)

func _reset_position(original_pos: Vector2):
	position = original_pos

func place_stone() -> bool:
	if can_place_stone():
		has_stone_block = true
		_setup_visuals()  # Update visual appearance
		return true
	return false