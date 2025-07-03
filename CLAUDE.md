# 2D Turn-Based Strategy Game

[![Tests](https://github.com/username/pyramid-builder/workflows/🧪%20Run%20Tests/badge.svg)](https://github.com/username/pyramid-builder/actions)
[![Coverage](https://img.shields.io/badge/coverage-90%25-brightgreen)](https://github.com/username/pyramid-builder/actions)
[![Godot](https://img.shields.io/badge/godot-4.2-blue)](https://godotengine.org)

## Project Setup
- **Engine:** Godot 4.2
- **Language:** GDScript 2.0
- **Target Platforms:** PC/Steam (initial), Mobile (later)

## Development Notes
- Using Godot 4.2 syntax and features
- Node-based architecture with modern GDScript conventions
- @export decorators for exposed variables
- PackedStringArray, Vector2i types
- Signal connections with .connect() method

## Testing & Quality Assurance
- **Framework:** GdUnit4 for comprehensive testing
- **Coverage:** 90%+ test coverage target
- **CI/CD:** Automated testing on every PR
- **TDD:** Test-driven development approach

### Running Tests
```bash
# Run all tests
./scripts/run_tests.sh

# Run with coverage
./scripts/run_tests.sh -c

# Run specific test
./scripts/run_tests.sh -t test_worker.gd

# Watch for changes and auto-run tests
./scripts/test_watch.sh
```

## Documentation Structure
- `docs/game-design.md` - Core gameplay mechanics and rules
- `docs/features.md` - Feature backlog and development phases
- `docs/technical-specs.md` - Architecture and technical implementation
- `docs/ui-ux.md` - Interface design and user experience
- `docs/roadmap.md` - Development timeline and milestones
- `docs/testing.md` - Test-driven development strategy