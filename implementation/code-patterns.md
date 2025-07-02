# Code Patterns and Conventions

## Established Patterns in Codebase

### GDScript Style
- **Type hints**: Extensively used throughout
- **Naming**: snake_case for variables/functions, PascalCase for classes
- **Constants**: UPPER_CASE (GRID_SIZE, TILE_SIZE, etc.)
- **Signals**: Descriptive names with consistent emit patterns

### Scene Structure Pattern
```
Main.tscn (entry point)
├── Camera2D
├── GameBoard (instance)
│   ├── TileContainer
│   ├── WorkerContainer  
│   ├── HighlightOverlay
│   └── GridOverlay
└── UI (CanvasLayer)
    └── HUD with panels
```

### Class Organization Pattern
```gdscript
class_name ClassName
extends BaseClass

# Exports first
@export var property: Type

# Constants
const CONSTANT_NAME = value

# Variables (grouped by purpose)
var grid_position: Vector2i
var action_points: int

# Onready variables
@onready var node_ref = $NodePath

# Built-in overrides (_ready, _input, etc.)
# Public methods
# Private methods (prefixed with _)
# Signal handlers (prefixed with _on_)
```

### Signal Pattern
```gdscript
# Signal declaration
signal action_performed(worker: Worker, action: String)

# Signal emission
action_performed.emit(self, "move")

# Signal connection
worker.action_performed.connect(_on_worker_action_performed)
```

### Animation Pattern
```gdscript
func _animate_something():
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(self, "property", target_value, duration)
```

### Grid Coordinate Pattern
```gdscript
# Always use Vector2i for grid coordinates
var grid_pos: Vector2i = Vector2i(x, y)

# Conversion functions
func world_to_grid(world_pos: Vector2) -> Vector2i:
    return Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
    return Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE/2, grid_pos.y * TILE_SIZE + TILE_SIZE/2)
```

### Input Handling Pattern
```gdscript
func _input(event):
    if event.is_action_pressed("action_name"):
        handle_action()
    elif event.is_action_pressed("left_click"):
        var global_pos = get_global_mouse_position()
        handle_click(global_pos)
```

### UI Update Pattern
```gdscript
func _update_ui():
    var selected_worker = get_selected_worker()
    if selected_worker:
        # Show worker-specific info
        label.text = "Worker " + str(index)
        button.disabled = not can_perform_action()
    else:
        # Show no selection state
        label.text = "No worker selected"
        button.visible = false
```

### Validation Pattern
```gdscript
func can_perform_action() -> bool:
    return condition1 and condition2 and condition3

func perform_action() -> bool:
    if can_perform_action():
        # Execute action
        # Update state
        # Emit signals
        return true
    return false
```

### Highlighting Pattern
```gdscript
# Clear previous highlights
highlight_overlay.clear_all_highlights()

# Set new highlights with color coding
for pos in valid_positions:
    var color = get_action_color(pos)
    highlight_overlay.set_highlight(pos, true, color)
```

### Error Handling Pattern
```gdscript
func get_tile_at(pos: Vector2i) -> Tile:
    if is_valid_position(pos):
        return tiles[pos.x][pos.y]
    return null  # Return null for invalid positions

func safe_operation(target):
    if not target:
        return  # Early return for null checks
    # Proceed with operation
```

### Constants and Configuration
```gdscript
# In relevant classes
const GRID_SIZE = 20
const TILE_SIZE = 32
const PYRAMID_CENTER = Vector2i(10, 10)

# Action costs
const MOVE_COST = 1
const QUARRY_COST = 1
const PLACE_COST = 1
```

### File Naming Convention
- **Scripts**: PascalCase matching class name (Worker.gd, GameBoard.gd)
- **Scenes**: PascalCase with .tscn extension (Main.tscn, Worker.tscn)
- **Documentation**: kebab-case with .md extension (game-design.md)

### Comment Style
```gdscript
# Single line explanations for complex logic
# No redundant comments for obvious code
# TODO comments for future improvements
# Section separators for logical groupings

func complex_function():
    # Calculate adjacent positions for movement validation
    var adjacent = get_adjacent_positions()
    
    # Filter based on terrain and occupancy
    for pos in adjacent:
        if is_valid_move_target(pos):
            valid_moves.append(pos)
```

### Testing Approach
- Manual testing through game interaction
- Debug prints for action confirmations
- Visual feedback for all actions
- UI state validation
- Edge case handling (boundaries, invalid actions)