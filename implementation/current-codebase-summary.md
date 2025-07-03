# Current Codebase Summary

## Quick Reference for Context Recovery

### Game Concept
Turn-based pyramid building game in ancient Egypt. Workers quarry stones and build a 3x3 pyramid in the center of a 20x20 grid map.

### Key Game Mechanics
- **Workers**: 2 units with 2 action points each per turn
- **Actions**: Move (1 AP), Quarry stone (1 AP), Place stone (1 AP)
- **Map**: 20x20 grid with desert, water (Nile), stone deposits, pyramid base
- **Goal**: Fill 3x3 pyramid base with stone blocks

### Core Code Architecture

#### Main Classes
1. **GameManager** (Singleton) - Game state, turn management, worker tracking
2. **GameBoard** - Grid management, input handling, worker/tile coordination  
3. **Worker** - Unit behavior, movement, actions, animations
4. **Tile** - Individual tile logic, terrain types, stone placement
5. **Main** - Scene controller, UI management
6. **HighlightOverlay** - Movement range visualization
7. **GridOverlay** - Visual grid lines

#### Key Systems
- **Grid System**: 20x20 Vector2i coordinates, 32px tiles
- **Turn System**: Worker cycling with AP management
- **Input System**: Left/right click, space bar, UI buttons
- **Animation System**: Smooth movement, quarry feedback
- **Highlight System**: Color-coded action indicators

### Critical Implementation Details

#### Terrain Types (Tile.gd)
```gdscript
enum TerrainType {
    DESERT,        # Passable, buildable
    STONE_DEPOSIT, # Impassable, quarryable  
    WATER,         # Impassable (Nile river)
    PYRAMID_BASE   # Passable, buildable (goal area)
}
```

#### Worker Actions Priority (GameBoard.gd)
1. Quarry stone (if adjacent deposit + can carry)
2. Move (if tile passable + empty)
3. Place stone (if valid location + has stones)

#### Map Layout
- **Nile River**: x=6,7 (vertical strip)
- **Pyramid**: Center 3x3 area (9,9 to 11,11)
- **Stone Deposits**: (3,5), (15,8), (12,16) with 5 stones each
- **Workers Start**: (2,10) and (18,10)

#### UI Layout
- **Worker Info**: Right side panel with AP, stones, actions
- **Turn Info**: Bottom right with turn counter, end turn button
- **Highlights**: Green=move, Yellow=quarry, Blue=place stone

### Important Godot 4.2 Patterns Used
- `@onready` and `@export` annotations
- `create_tween()` for animations
- `queue_redraw()` for visual updates
- `.emit()` and `.connect()` for signals
- `Array[Type]` for typed arrays
- `.instantiate()` for scene creation

### File Dependencies
- **Main.tscn** → GameBoard.tscn → Worker.tscn
- **GameManager** (autoload) ← referenced by Main, GameBoard
- **All scripts** use Tile and Worker classes
- **Overlays** depend on GRID_SIZE and TILE_SIZE constants

### Current Game State
- Phase 1: ✅ Complete (grid, workers, basic gameplay)
- Phase 2: 🔄 Partially complete (stone mechanics implemented)
- Animations: ✅ Worker movement, quarry feedback
- UI: ✅ Functional panels and controls
- Victory: ✅ Pyramid completion detection

### Git Status
- Repository: `pyramid-builder`
- Last feature: Comprehensive testing infrastructure with GdUnit4
- Branch structure: Feature branches with PRs and automated testing
- Commit style: Descriptive without Claude attribution
- CI/CD: Automated testing on every PR with GitHub Actions