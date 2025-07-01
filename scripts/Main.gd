extends Node2D

@onready var game_board = $GameBoard
@onready var worker_label = $UI/HUD/WorkerInfo/WorkerLabel
@onready var ap_label = $UI/HUD/WorkerInfo/APLabel
@onready var stone_label = $UI/HUD/WorkerInfo/StoneLabel
@onready var place_stone_button = $UI/HUD/WorkerInfo/PlaceStoneButton
@onready var turn_label = $UI/HUD/TurnInfo/TurnLabel
@onready var end_turn_button = $UI/HUD/TurnInfo/EndTurnButton

func _ready():
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	place_stone_button.pressed.connect(_on_place_stone_pressed)
	GameManager.worker_changed.connect(_on_worker_changed)
	GameManager.turn_changed.connect(_on_turn_changed)
	_update_ui()

func _input(event):
	if event.is_action_pressed("end_turn"):
		game_board.deselect_worker()
		GameManager.end_current_worker_turn()
	elif event.is_action_pressed("left_click"):
		var global_pos = get_global_mouse_position()
		game_board.handle_click(global_pos)
	elif event.is_action_pressed("right_click"):
		game_board.deselect_worker()

func _on_end_turn_pressed():
	game_board.deselect_worker()
	GameManager.end_current_worker_turn()

func _on_place_stone_pressed():
	if game_board.selected_worker:
		game_board.place_stone_at_worker_position()

func _on_worker_changed():
	_update_ui()

func _on_turn_changed():
	_update_ui()

func _update_ui():
	var selected_worker = game_board.selected_worker
	if selected_worker:
		var worker_index = GameManager.workers.find(selected_worker)
		worker_label.text = "Worker " + str(worker_index + 1)
		ap_label.text = "Action Points: " + str(selected_worker.action_points) + "/2"
		stone_label.text = "Stones: " + str(selected_worker.carried_stones)
		
		# Enable/disable place stone button
		var can_place = selected_worker.can_place_stone() and game_board.can_place_stone_at_worker_position(selected_worker)
		place_stone_button.disabled = not can_place
		place_stone_button.visible = true
	else:
		worker_label.text = "No worker selected"
		ap_label.text = "Action Points: -"
		stone_label.text = "Stones: -"
		place_stone_button.visible = false
	
	turn_label.text = "Turn: " + str(GameManager.turn_number)
