class_name Worker
extends Node2D

@export var grid_position: Vector2i
@export var action_points: int = 2
@export var max_action_points: int = 2
@export var carried_stones: int = 0
@export var max_stones: int = 1

const TILE_SIZE = 32
var is_selected: bool = false

signal worker_selected(worker: Worker)
signal worker_moved(worker: Worker, new_position: Vector2i)
signal action_performed(worker: Worker, action: String)

func _ready():
	_setup_visuals()
	_update_position()

func _setup_visuals():
	var sprite = Sprite2D.new()
	add_child(sprite)
	
	# Create a simple worker representation
	var texture = ImageTexture.new()
	var image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.6, 0.4))  # Worker skin color
	
	# Add simple details
	for x in range(8, 16):
		for y in range(4, 8):
			image.set_pixel(x, y, Color(0.4, 0.2, 0.1))  # Hair
	
	for x in range(10, 14):
		for y in range(8, 12):
			image.set_pixel(x, y, Color(0.9, 0.7, 0.5))  # Face
	
	texture.set_image(image)
	sprite.texture = texture
	
	# Add selection indicator
	var selection_circle = Node2D.new()
	add_child(selection_circle)
	selection_circle.visible = false
	selection_circle.name = "SelectionCircle"

func _draw():
	if is_selected:
		draw_circle(Vector2.ZERO, 20, Color(1, 1, 0, 0.3))
		draw_arc(Vector2.ZERO, 20, 0, TAU, 32, Color(1, 1, 0), 2.0)

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		worker_selected.emit(self)

func set_selected(selected: bool):
	is_selected = selected
	queue_redraw()

func _update_position():
	position = Vector2(grid_position.x * TILE_SIZE + TILE_SIZE/2, grid_position.y * TILE_SIZE + TILE_SIZE/2)

func can_move_to(target_position: Vector2i) -> bool:
	if action_points <= 0:
		return false
	
	var distance = abs(target_position.x - grid_position.x) + abs(target_position.y - grid_position.y)
	return distance == 1  # Only adjacent moves allowed

func move_to(target_position: Vector2i) -> bool:
	if can_move_to(target_position):
		grid_position = target_position
		_update_position()
		action_points -= 1
		worker_moved.emit(self, target_position)
		action_performed.emit(self, "move")
		return true
	return false

func can_quarry() -> bool:
	return action_points > 0 and carried_stones < max_stones

func quarry_stone() -> bool:
	if can_quarry():
		_play_work_animation()
		carried_stones += 1
		action_points -= 1
		action_performed.emit(self, "quarry")
		return true
	return false

func _play_work_animation():
	# Create a simple bounce animation for the worker
	var tween = create_tween()
	var original_scale = scale
	
	# Bounce effect
	tween.tween_property(self, "scale", Vector2(1.2, 0.8), 0.15)
	tween.tween_property(self, "scale", original_scale, 0.15)

func can_place_stone() -> bool:
	return action_points > 0 and carried_stones > 0

func place_stone() -> bool:
	if can_place_stone():
		carried_stones -= 1
		action_points -= 1
		action_performed.emit(self, "place")
		return true
	return false

func reset_action_points():
	action_points = max_action_points

func get_adjacent_positions() -> Array[Vector2i]:
	var adjacent: Array[Vector2i] = []
	adjacent.append(grid_position + Vector2i(0, -1))  # Up
	adjacent.append(grid_position + Vector2i(0, 1))   # Down
	adjacent.append(grid_position + Vector2i(-1, 0))  # Left
	adjacent.append(grid_position + Vector2i(1, 0))   # Right
	return adjacent
