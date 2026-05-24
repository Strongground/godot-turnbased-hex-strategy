# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Turn-based hexagonal strategy game in Godot 4.6, inspired by Panzer General / Battle Isle. The engine is data-driven so any historical period can be represented by swapping out a "theme" package.

## Commands

The Godot binary available in this workspace is `godot461`.

```bash
# Syntax/parse check
godot461 --headless --path . --quit

# Entry-scene startup check
godot461 --headless --path . --scene res://scenes/MainMenu.tscn --quit-after 30

# Scenario headless test (sets up writable user dir in /tmp automatically)
./tools/run_scenario_1_headless.sh

# Regenerate JSON from YAML after editing theme data
python devtools/yaml_to_json.py -sd themes/example-modern -td themes/example-modern
```

There is no automated test suite. Validation is manual: run the checks above, then do a smoke playthrough (select unit → move → attack) in the editor.

## Architecture

### Theme / Content System

All game content lives under `themes/<theme-name>/`. YAML files (`.yml`) are the human-editable source of truth; the `.json` files are generated from them and must be committed alongside. **Never edit `.json` files directly.** After changing any `.yml` file, run `yaml_to_json.py` before committing.

`classes/theme_mgr.gd` loads units, weapons, factions, scenarios, modifiers, tiles, effects, and music from JSON at runtime. Every content reference (unit IDs, weapon IDs, faction IDs) resolves through this loader.

### Manager System (Async Initialization)

All major systems extend `GameManager` (`classes/game_manager.gd`). The key rule: **never do real work in `_ready()`** — put everything in `_initialize_internal()` and `await` each dependency before doing your own setup.

```gdscript
func _initialize_internal() -> Future:
    if themeMgr != null and is_instance_valid(themeMgr):
        await themeMgr.initialize()
    # ... your setup here
    return true
```

Initialization order (matches dependency graph):
1. SettingsManager, ThemeManager, PlayerManager, WeatherManager — no dependencies
2. FactionManager, SfxManager — depend on ThemeManager
3. MusicManager — depends on SettingsManager + ThemeManager

### Core Gameplay (`classes/game.gd`)

Central orchestrator (~1400 lines). Owns: hex A* pathfinding, entity/unit placement, turn flow, combat resolution, and UI coordination. All managers are wired to it via `@export` variables.

**Important entity snapping timing:** entities must not snap to grid in their own `_ready()`. `game.gd` emits a `setup_complete` signal after `_setup_game()` finishes; entities listen to that signal to snap to their hex center. This is required because hex coordinate data isn't available until after `_setup_game()` runs.

### Unit System (`classes/unit.gd`)

Data model for all combatants (~1400 lines). Key exported properties: `unit_id`, `unit_faction`, `unit_strength`, `movement_points`, `fuel` (-1 = unlimited), `armor`, `weapons[]`, `ammo`, `modifiers[]`. Combat, damage, and modifier application all live here.

### Scene Layout

- `classes/` — Core gameplay logic (game, unit, entity, theme_mgr, gui, etc.)
- `scenes/` — UI scenes and manager scripts (MainMenu, PlayerManager, WeatherManager, etc.)
- `themes/` — Data packages (YAML source + generated JSON + graphics/sounds/maps)
- `devtools/` — Build tools (yaml_to_json.py, battle_calculator.py)
- `scripts/globals.gd` — Global singleton (autoload: `globals`)

### Scenarios

Each scenario has a definition in `themes/<theme>/scenarios.yml` (converted to `scenarios.json`) and a corresponding Godot scene at `themes/<theme>/scenarios/scenario_N.tscn`. The scene contains a Game node, a TileMapLayer for the hex grid, placed unit entities, and victory-point markers.

## Key Constraints

- Manager/setup initialization order is load-bearing; change with care.
- Do not modify code under `addons/` unless explicitly requested.
- Hardcoded enums/IDs in `unit.gd` are known technical debt (tracked in `TODO.md`).
- Read `TODO.md` before implementing non-trivial features to check current priorities.
