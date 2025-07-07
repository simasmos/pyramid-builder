# Test-Driven Development with GUT Framework

## Overview

This document outlines the Test-Driven Development (TDD) approach for the Pyramid Builder game using GUT (Godot Unit Test) framework version 9.4.0 for Godot 4.2.

## TDD Philosophy for Game Development

### Core Principles
1. **Red-Green-Refactor Cycle**: Write failing tests first, make them pass, then refactor
2. **Behavioral Testing**: Focus on what the code should do, not how it does it
3. **Incremental Development**: Build features piece by piece with tests as safety nets
4. **Living Documentation**: Tests serve as executable specifications

### Benefits for Game Development
- **Regression Prevention**: Catch bugs before they reach players
- **Design Validation**: Ensure game mechanics work as intended
- **Refactoring Safety**: Modify code confidently without breaking existing features
- **Collaboration**: Clear specifications for team members

## GUT Framework Setup

### Installation
1. Install GUT via Godot Asset Library
2. Enable the plugin in Project Settings
3. Configure test runner settings

### Project Structure
```
pyramid-builder/
├── scripts/
│   ├── GameManager.gd
│   ├── Worker.gd
│   └── ...
├── test/
│   ├── unit/
│   │   ├── test_game_manager.gd
│   │   ├── test_worker.gd
│   │   └── test_tile.gd
│   ├── integration/
│   │   ├── test_worker_actions.gd
│   │   └── test_turn_system.gd
│   └── acceptance/
│       ├── test_game_flow.gd
│       └── test_victory_conditions.gd
└── addons/gut/
```

## Testing Strategy by Component

### 1. Game State Management (GameManager)

**Test Categories:**
- Turn progression logic
- Worker state tracking
- Victory condition detection
- Resource management

**Example Test Structure:**
```gdscript
extends GutTest

func test_turn_advances_when_all_workers_finish():
    # Arrange
    var game_manager = GameManager.new()
    game_manager.initialize_game()
    
    # Act
    game_manager.end_worker_turn()
    game_manager.end_worker_turn()
    
    # Assert
    assert_eq(game_manager.turn_number, 2)

func test_victory_detected_when_pyramid_complete():
    # Arrange
    var game_manager = GameManager.new()
    var pyramid_positions = _get_pyramid_positions()
    
    # Act
    _place_stones_at_positions(pyramid_positions)
    
    # Assert
    assert_true(game_manager.check_victory())
```

### 2. Worker Behavior (Worker)

**Test Categories:**
- Action point management
- Movement validation
- Stone carrying mechanics
- Animation state handling

**Example Test Structure:**
```gdscript
extends GutTest

func test_worker_moves_to_valid_adjacent_tile():
    # Arrange
    var worker = Worker.new()
    worker.grid_position = Vector2i(5, 5)
    worker.action_points = 2
    
    # Act
    var result = worker.move_to(Vector2i(6, 5))
    
    # Assert
    assert_true(result)
    assert_eq(worker.grid_position, Vector2i(6, 5))
    assert_eq(worker.action_points, 1)

func test_worker_cannot_move_without_action_points():
    # Arrange
    var worker = Worker.new()
    worker.action_points = 0
    
    # Act
    var result = worker.move_to(Vector2i(6, 5))
    
    # Assert
    assert_false(result)
```

### 3. Grid System (GameBoard)

**Test Categories:**
- Coordinate validation
- Tile state management
- Input handling
- Highlight system

**Example Test Structure:**
```gdscript
extends GutTest

func test_valid_grid_position_returns_true():
    # Arrange
    var game_board = GameBoard.new()
    
    # Act & Assert
    assert_true(game_board.is_valid_position(Vector2i(0, 0)))
    assert_true(game_board.is_valid_position(Vector2i(19, 19)))
    assert_false(game_board.is_valid_position(Vector2i(-1, 0)))
    assert_false(game_board.is_valid_position(Vector2i(20, 0)))
```

### 4. Terrain System (Tile)

**Test Categories:**
- Terrain type properties
- Stone placement validation
- Visual state updates
- Passability rules

**Example Test Structure:**
```gdscript
extends GutTest

func test_desert_tile_is_passable():
    # Arrange
    var tile = Tile.new()
    tile.terrain_type = Tile.TerrainType.DESERT
    
    # Act & Assert
    assert_true(tile.is_passable())
    assert_true(tile.can_place_stone())

func test_water_tile_is_impassable():
    # Arrange
    var tile = Tile.new()
    tile.terrain_type = Tile.TerrainType.WATER
    
    # Act & Assert
    assert_false(tile.is_passable())
    assert_false(tile.can_place_stone())
```

## TDD Workflow for Game Features

### Phase 1: Feature Planning
1. **Define Acceptance Criteria**: What should the feature do?
2. **Identify Components**: Which classes/methods need testing?
3. **Plan Test Scenarios**: Happy path, edge cases, error conditions

### Phase 2: Test-First Development
1. **Write Failing Tests**: Start with the simplest test case
2. **Run Tests**: Verify they fail for the right reasons
3. **Implement Minimum Code**: Make the test pass
4. **Refactor**: Clean up code while keeping tests green

### Phase 3: Integration Testing
1. **Component Integration**: Test how components work together
2. **Scene Testing**: Test complete game scenarios
3. **Performance Testing**: Ensure acceptable performance

## Testing Patterns for Game Development

### 1. State-Based Testing
```gdscript
func test_worker_state_after_quarrying():
    # Arrange
    var worker = Worker.new()
    var stone_deposit = _create_stone_deposit()
    
    # Act
    worker.quarry_stone(stone_deposit)
    
    # Assert
    assert_eq(worker.stones_carried, 1)
    assert_eq(worker.action_points, 1)
```

### 2. Behavior-Based Testing
```gdscript
func test_worker_emits_action_signal():
    # Arrange
    var worker = Worker.new()
    watch_signals(worker)
    
    # Act
    worker.move_to(Vector2i(1, 1))
    
    # Assert
    assert_signal_emitted(worker, "action_performed")
```

### 3. Parameterized Testing
```gdscript
func test_movement_costs_action_point(params=use_parameters([
    [Vector2i(1, 0), 1],  # Right
    [Vector2i(0, 1), 1],  # Down
    [Vector2i(-1, 0), 1], # Left
    [Vector2i(0, -1), 1]  # Up
])):
    # Arrange
    var worker = Worker.new()
    worker.action_points = 2
    
    # Act
    worker.move_to(params[0])
    
    # Assert
    assert_eq(worker.action_points, 2 - params[1])
```

### 4. Scene Testing
```gdscript
func test_complete_game_scene():
    # Arrange
    var game_scene = preload("res://scenes/Main.tscn").instantiate()
    add_child_autofree(game_scene)
    
    # Act
    game_scene.start_game()
    
    # Assert
    assert_not_null(game_scene.get_node("GameBoard"))
    assert_eq(game_scene.get_workers().size(), 2)
```

## Testing Best Practices

### 1. Test Organization
- **Group Related Tests**: Use inner classes for related functionality
- **Descriptive Names**: Test names should describe the scenario
- **Arrange-Act-Assert**: Clear test structure

### 2. Test Independence
- **No Test Dependencies**: Each test should run independently
- **Clean State**: Reset game state between tests
- **Isolated Components**: Test one thing at a time

### 3. Mock and Stub Usage
```gdscript
func test_worker_action_with_mocked_tile():
    # Arrange
    var mock_tile = double(Tile)
    stub(mock_tile, "is_passable").to_return(true)
    
    var worker = Worker.new()
    
    # Act
    worker.move_to_tile(mock_tile)
    
    # Assert
    assert_called(mock_tile, "is_passable")
```

### 4. Performance Testing
```gdscript
func test_pathfinding_performance():
    # Arrange
    var start_time = Time.get_ticks_msec()
    
    # Act
    var path = pathfinder.find_path(Vector2i(0, 0), Vector2i(19, 19))
    
    # Assert
    var elapsed = Time.get_ticks_msec() - start_time
    assert_lt(elapsed, 100)  # Should complete in under 100ms
```

## Continuous Integration

### Running Tests
- **Local Development**: Use GUT GUI for interactive testing
- **CI/CD Pipeline**: Use GUT command-line interface
- **Test Coverage**: Monitor code coverage metrics

### Test Automation
```bash
# Example CI command
godot --headless --script addons/gut/gut_cmdln.gd -gtest_runner
```

## Implementation Roadmap

### Phase 1: Foundation Testing
1. Set up GUT framework
2. Write basic unit tests for existing components
3. Establish testing patterns and conventions

### Phase 2: Feature Development
1. Apply TDD for new features
2. Refactor existing code with test coverage
3. Add integration tests

### Phase 3: Advanced Testing
1. Performance testing
2. Scene testing
3. Input simulation testing
4. Audio/visual testing

## Conclusion

Test-Driven Development with GUT provides a solid foundation for reliable game development. By writing tests first, we ensure our pyramid building game mechanics work correctly, remain maintainable, and can be extended safely.

The key is to start simple, build incrementally, and let tests guide the design of robust, well-structured game code.