extends Node

signal worker_changed
signal turn_changed
signal game_won

const WorkerClass = preload("res://scripts/Worker.gd")
var workers: Array[WorkerClass] = []
var current_worker_index: int = 0
var turn_number: int = 1
var game_board: Node2D
var pyramid_completed: bool = false

const GRID_SIZE = 20
const PYRAMID_CENTER = Vector2i(10, 10)

func _ready():
	_initialize_game()

func _initialize_game():
	# This will be called when the game starts
	pass

func register_game_board(board: Node2D):
	game_board = board

func add_worker(worker: WorkerClass):
	workers.append(worker)
	worker.worker_selected.connect(_on_worker_selected)
	worker.action_performed.connect(_on_worker_action_performed)

func get_current_worker() -> WorkerClass:
	if workers.size() > 0 and current_worker_index < workers.size():
		return workers[current_worker_index]
	return null

func _on_worker_selected(worker: WorkerClass):
	for i in range(workers.size()):
		if workers[i] == worker:
			current_worker_index = i
			_update_worker_selection()
			worker_changed.emit()
			break

func _update_worker_selection():
	for i in range(workers.size()):
		workers[i].set_selected(i == current_worker_index)

func _clear_worker_selection():
	for worker in workers:
		worker.set_selected(false)

func _on_worker_action_performed(worker: WorkerClass, action: String):
	print("Worker performed action: ", action)
	worker_changed.emit()
	
	# Check if pyramid is completed after each action
	if action == "place":
		_check_pyramid_completion()

func end_turn():
	_start_new_turn()

func _next_worker():
	# Clear current selection
	_clear_worker_selection()
	
	current_worker_index = (current_worker_index + 1) % workers.size()
	
	# If we've cycled through all workers, start a new turn
	if current_worker_index == 0:
		_start_new_turn()
	else:
		# Check if all workers are out of action points
		var all_workers_done = true
		for worker in workers:
			if worker.action_points > 0:
				all_workers_done = false
				break
		
		if all_workers_done:
			_start_new_turn()
	
	worker_changed.emit()

func _start_new_turn():
	turn_number += 1
	
	# Reset all workers' action points
	for worker in workers:
		worker.reset_action_points()
	
	turn_changed.emit()

func can_worker_act() -> bool:
	var current_worker = get_current_worker()
	return current_worker != null and current_worker.action_points > 0

func is_position_valid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE

func get_worker_at_position(pos: Vector2i) -> WorkerClass:
	for worker in workers:
		if worker.grid_position == pos:
			return worker
	return null

func _check_pyramid_completion():
	if not game_board:
		return
	
	# Check if the 3x3 pyramid area is completed
	var pyramid_tiles_filled = 0
	var total_pyramid_tiles = 9
	
	for x in range(PYRAMID_CENTER.x - 1, PYRAMID_CENTER.x + 2):
		for y in range(PYRAMID_CENTER.y - 1, PYRAMID_CENTER.y + 2):
			var tile = game_board.get_tile_at(Vector2i(x, y))
			if tile and tile.has_stone_block:
				pyramid_tiles_filled += 1
	
	if pyramid_tiles_filled >= total_pyramid_tiles:
		pyramid_completed = true
		game_won.emit()
		print("Pyramid completed! Victory!")

func get_pyramid_progress() -> float:
	if not game_board:
		return 0.0
	
	var pyramid_tiles_filled = 0
	var total_pyramid_tiles = 9
	
	for x in range(PYRAMID_CENTER.x - 1, PYRAMID_CENTER.x + 2):
		for y in range(PYRAMID_CENTER.y - 1, PYRAMID_CENTER.y + 2):
			var tile = game_board.get_tile_at(Vector2i(x, y))
			if tile and tile.has_stone_block:
				pyramid_tiles_filled += 1
	
	return float(pyramid_tiles_filled) / float(total_pyramid_tiles)