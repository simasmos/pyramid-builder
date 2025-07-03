# Test-Driven Development Strategy - Pyramid Builder

## Overview
This document outlines a comprehensive test-driven development (TDD) approach for the Pyramid Builder game using GdUnit4, Godot's premier testing framework.

## Testing Philosophy

### TDD Cycle
1. **Red**: Write a failing test that defines desired behavior
2. **Green**: Write minimal code to make the test pass
3. **Refactor**: Improve code while keeping tests green
4. **Repeat**: Continue cycle for each new feature

### Testing Pyramid
```
    /\     UI/Integration Tests (Few)
   /  \    
  /____\   Component Tests (More)
 /______\  Unit Tests (Most)
```

## GdUnit4 Setup

### Installation
```bash
# Install GdUnit4 plugin through Godot Asset Library
# Or download from: https://github.com/MikeSchulze/gdUnit4
```

### Project Structure
```
test/
├── unit/                    # Pure logic tests
│   ├── test_game_manager.gd
│   ├── test_tile.gd
│   ├── test_worker.gd
│   └── test_grid_logic.gd
├── integration/             # Component interaction tests
│   ├── test_worker_movement.gd
│   ├── test_stone_mechanics.gd
│   └── test_turn_system.gd
├── scene/                   # Scene-based tests
│   ├── test_game_board.gd
│   ├── test_main_scene.gd
│   └── test_ui_components.gd
└── helpers/                 # Test utilities
    ├── test_data_builder.gd
    └── test_assertions.gd
```

## Core Testing Strategies

### 1. Game State Management (GameManager)

#### Test Categories
- **State Transitions**: Turn progression, worker switching
- **Action Point Management**: AP consumption, restoration
- **Victory Conditions**: Pyramid completion detection
- **Data Persistence**: Game state consistency

#### Example Test Structure
```gdscript
# test/unit/test_game_manager.gd
extends GdUnitTestSuite

func before_test():
    GameManager.reset_game()

func test_worker_turn_progression():
    # Red: Define expected behavior
    GameManager.current_worker_index = 0
    GameManager.workers[0].action_points = 0
    
    # Green: Implement next_worker() method
    GameManager.next_worker()
    
    # Assert: Verify state change
    assert_int(GameManager.current_worker_index).is_equal(1)
    assert_int(GameManager.workers[1].action_points).is_equal(2)

func test_pyramid_completion_detection():
    # Setup: Fill pyramid base with stones
    var pyramid_tiles = _get_pyramid_base_tiles()
    for tile in pyramid_tiles:
        tile.has_stone = true
    
    # Test: Check victory condition
    var is_complete = GameManager.check_pyramid_completion()
    assert_bool(is_complete).is_true()
```

### 2. Grid and Tile Logic

#### Test Focus Areas
- **Coordinate System**: Grid-to-world conversion
- **Terrain Types**: Passability, quarryability
- **Stone Mechanics**: Placement, removal, limits
- **Adjacency Logic**: Valid action detection

#### Test Implementation
```gdscript
# test/unit/test_tile.gd
extends GdUnitTestSuite

func test_tile_passability():
    # Test each terrain type
    var desert_tile = Tile.new()
    desert_tile.terrain_type = Tile.TerrainType.DESERT
    assert_bool(desert_tile.is_passable()).is_true()
    
    var water_tile = Tile.new()
    water_tile.terrain_type = Tile.TerrainType.WATER
    assert_bool(water_tile.is_passable()).is_false()

func test_stone_placement_validation():
    var pyramid_tile = Tile.new()
    pyramid_tile.terrain_type = Tile.TerrainType.PYRAMID_BASE
    pyramid_tile.has_stone = false
    
    assert_bool(pyramid_tile.can_place_stone()).is_true()
    
    pyramid_tile.has_stone = true
    assert_bool(pyramid_tile.can_place_stone()).is_false()
```

### 3. Worker Behavior Testing

#### Key Test Scenarios
- **Movement Validation**: Valid destinations, collision detection
- **Action Execution**: Quarry, place stone, move
- **State Management**: AP, inventory, position
- **Animation Integration**: Movement tweens, feedback

#### Worker Test Example
```gdscript
# test/unit/test_worker.gd
extends GdUnitTestSuite

var worker: Worker
var mock_game_board: GameBoard

func before_test():
    worker = Worker.new()
    worker.action_points = 2
    worker.stones_carried = 0
    worker.grid_position = Vector2i(5, 5)
    
    mock_game_board = GameBoard.new()

func test_worker_movement():
    # Test valid movement
    var target_pos = Vector2i(5, 6)
    var can_move = worker.can_move_to(target_pos, mock_game_board)
    assert_bool(can_move).is_true()
    
    # Execute movement
    worker.move_to(target_pos)
    assert_vector2i(worker.grid_position).is_equal(target_pos)
    assert_int(worker.action_points).is_equal(1)

func test_stone_quarrying():
    # Setup: Adjacent stone deposit
    var stone_pos = Vector2i(5, 6)
    mock_game_board.set_tile_terrain(stone_pos, Tile.TerrainType.STONE_DEPOSIT)
    
    # Test: Quarry action
    var can_quarry = worker.can_quarry_at(stone_pos, mock_game_board)
    assert_bool(can_quarry).is_true()
    
    worker.quarry_stone(stone_pos, mock_game_board)
    assert_int(worker.stones_carried).is_equal(1)
    assert_int(worker.action_points).is_equal(1)
```

### 4. Integration Testing

#### Turn System Integration
```gdscript
# test/integration/test_turn_system.gd
extends GdUnitTestSuite

func test_complete_worker_turn():
    # Setup full game state
    var game_board = GameBoard.new()
    game_board.initialize_board()
    
    var worker = game_board.workers[0]
    worker.grid_position = Vector2i(2, 10)
    worker.action_points = 2
    
    # Execute full turn sequence
    worker.move_to(Vector2i(3, 10))  # 1 AP
    worker.move_to(Vector2i(4, 10))  # 1 AP
    
    # Verify turn completion
    assert_int(worker.action_points).is_equal(0)
    assert_bool(GameManager.is_worker_turn_complete()).is_true()
```

#### Stone Mechanics Integration
```gdscript
# test/integration/test_stone_mechanics.gd
extends GdUnitTestSuite

func test_quarry_to_pyramid_workflow():
    # Setup: Worker near stone deposit
    var worker = Worker.new()
    worker.grid_position = Vector2i(3, 4)  # Adjacent to stone deposit at (3,5)
    worker.action_points = 2
    
    # Phase 1: Quarry stone
    worker.quarry_stone(Vector2i(3, 5), game_board)
    assert_int(worker.stones_carried).is_equal(1)
    
    # Phase 2: Move to pyramid
    worker.move_to(Vector2i(9, 9))  # Pyramid base
    
    # Phase 3: Place stone
    worker.place_stone(game_board)
    assert_int(worker.stones_carried).is_equal(0)
    assert_bool(game_board.get_tile(Vector2i(9, 9)).has_stone).is_true()
```

### 5. UI Component Testing

#### UI State Testing
```gdscript
# test/scene/test_ui_components.gd
extends GdUnitTestSuite

func test_worker_info_panel_updates():
    # Setup scene
    var main_scene = preload("res://scenes/Main.tscn").instantiate()
    add_child(main_scene)
    
    var worker_panel = main_scene.get_node("UI/WorkerInfoPanel")
    
    # Test: Worker selection updates UI
    GameManager.selected_worker = GameManager.workers[0]
    GameManager.selected_worker.action_points = 1
    GameManager.selected_worker.stones_carried = 1
    
    main_scene._update_worker_info()
    
    assert_str(worker_panel.get_node("APLabel").text).is_equal("AP: 1/2")
    assert_str(worker_panel.get_node("StonesLabel").text).is_equal("Stones: 1")
```

### 6. Performance Testing

#### Frame Rate Monitoring
```gdscript
# test/performance/test_performance.gd
extends GdUnitTestSuite

func test_grid_rendering_performance():
    var game_board = GameBoard.new()
    game_board.initialize_board()
    
    var start_time = Time.get_time_usec()
    
    # Force full grid redraw
    game_board.queue_redraw()
    await get_tree().process_frame
    
    var end_time = Time.get_time_usec()
    var render_time = end_time - start_time
    
    # Assert render time under 16ms (60fps)
    assert_int(render_time).is_less(16000)
```

### 7. Animation Testing

#### Movement Animation Validation
```gdscript
# test/integration/test_animations.gd
extends GdUnitTestSuite

func test_worker_movement_animation():
    var worker = Worker.new()
    add_child(worker)
    
    worker.grid_position = Vector2i(5, 5)
    worker.position = Vector2(160, 160)  # 5*32, 5*32
    
    # Start movement animation
    worker.animate_move_to(Vector2i(6, 5))
    
    # Wait for animation completion
    await worker.movement_complete
    
    # Verify final position
    assert_vector2(worker.position).is_equal(Vector2(192, 160))
    assert_vector2i(worker.grid_position).is_equal(Vector2i(6, 5))
```

## Test Data Management

### Test Data Builder Pattern
```gdscript
# test/helpers/test_data_builder.gd
class_name TestDataBuilder

static func create_worker(pos: Vector2i = Vector2i(0, 0), ap: int = 2) -> Worker:
    var worker = Worker.new()
    worker.grid_position = pos
    worker.action_points = ap
    worker.stones_carried = 0
    return worker

static func create_game_board_with_workers() -> GameBoard:
    var board = GameBoard.new()
    board.initialize_board()
    return board

static func create_pyramid_completion_state() -> GameBoard:
    var board = create_game_board_with_workers()
    # Fill pyramid base with stones
    for x in range(9, 12):
        for y in range(9, 12):
            board.get_tile(Vector2i(x, y)).has_stone = true
    return board
```

## Continuous Integration

### Test Automation
```yaml
# .github/workflows/test.yml
name: Run Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Godot
        uses: lihop/setup-godot@v1
        with:
          godot-version: '4.2'
      - name: Run GdUnit4 Tests
        run: |
          godot --headless --script addons/gdUnit4/bin/ProjectScanner.gd
          godot --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd
```

## Best Practices

### 1. Test Organization
- **One test class per production class**
- **Group related tests in test suites**
- **Use descriptive test names that explain behavior**
- **Keep tests independent and isolated**

### 2. Test Data
- **Use fresh test data for each test**
- **Mock external dependencies**
- **Create test data builders for complex objects**
- **Clean up resources after tests**

### 3. Assertions
- **Use specific assertion methods**
- **Assert on behavior, not implementation**
- **Include meaningful error messages**
- **Test edge cases and error conditions**

### 4. Game-Specific Considerations
- **Test game state transitions carefully**
- **Mock or stub random elements**
- **Test both success and failure scenarios**
- **Verify UI updates reflect game state**

## TDD Implementation Phases

### Phase 1: Foundation Tests
1. **GameManager state management**
2. **Tile terrain system**
3. **Worker basic actions**
4. **Grid coordinate system**

### Phase 2: Feature Tests
1. **Turn management system**
2. **Stone quarrying mechanics**
3. **Pyramid building logic**
4. **Victory condition detection**

### Phase 3: Integration Tests
1. **Complete gameplay workflows**
2. **UI component interactions**
3. **Animation system integration**
4. **Performance benchmarks**

### Phase 4: Edge Case Tests
1. **Error handling and recovery**
2. **Boundary condition testing**
3. **Resource exhaustion scenarios**
4. **Invalid input handling**

## Metrics and Coverage

### Code Coverage Goals
- **Unit Tests**: 90%+ coverage
- **Integration Tests**: 70%+ coverage
- **Critical Path**: 100% coverage

### Test Quality Metrics
- **Test execution time**: <30 seconds full suite
- **Test reliability**: 99%+ pass rate
- **Code quality**: No test code duplication

## Conclusion

This TDD approach ensures:
- **Robust game logic** through comprehensive testing
- **Maintainable codebase** with clear test documentation
- **Confident refactoring** supported by test safety net
- **Quality assurance** through automated testing pipeline

By following this strategy, new features are developed test-first, ensuring reliability and maintainability throughout the development lifecycle.