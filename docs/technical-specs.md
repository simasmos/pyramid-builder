# Technical Specifications - Pyramid Builder

## Architecture
- **Scene Structure**: Modular scenes for game states
- **Singleton Pattern**: GameManager for global state and turn management
- **Grid System**: 20x20 coordinate system with Vector2i positions

## Core Systems

### Game Board
- **Grid Size**: 20x20 squares
- **Coordinate System**: Vector2i (0,0 to 19,19)
- **Terrain Types**: Desert, StoneDeposit, Water
- **Pyramid Position**: Center tiles (9,9 to 11,11)

### Worker System
- **Action Points**: 2 AP per worker per turn
- **Actions**: Move (1 AP), Quarry (1 AP), Place Stone (1 AP)
- **Movement**: 4-directional (up, down, left, right)
- **Inventory**: Each worker can carry stone blocks

### Turn Management
- **Turn Order**: Cycle through workers
- **Action Validation**: Check AP availability and valid actions
- **State Tracking**: Current worker, remaining AP, game phase

### Resource System
- **Stone Deposits**: 3 deposits with finite stone blocks
- **Stone Inventory**: Per-worker stone carrying capacity
- **Placement Rules**: Adjacent to existing pyramid structure

## Data Structures
```gdscript
class_name Worker
var position: Vector2i
var action_points: int = 2
var carried_stones: int = 0
var max_stones: int = 1

class_name Tile
var terrain_type: TerrainType
var position: Vector2i
var has_stone_block: bool = false
var stone_deposit_remaining: int = 0

enum TerrainType {
    DESERT,
    STONE_DEPOSIT,
    WATER,
    PYRAMID_BASE
}
```

## Scene Organization
- Main.tscn - Entry point and game management
- GameBoard.tscn - 20x20 grid and tile rendering
- Worker.tscn - Worker unit representation
- Tile.tscn - Individual tile with terrain rendering
- UI/GameHUD.tscn - Action points, worker info, controls
- Managers/GameManager.gd - Global state and rules