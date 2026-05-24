# Copilot Workspace Instructions

## Purpose
These instructions are the always-on entry point for coding agents in this repository.

## First Read
- Read `AGENTS.md` first before making non-trivial changes.
- Treat `AGENTS.md` as the source of truth for architecture, validation flow, and do/don’t rules.

## Working Style
- Keep changes minimal and scoped to the user request.
- Prefer theme-driven/data-driven implementations over hardcoded gameplay data.
- Preserve existing scene/script contracts unless explicitly asked to change them.

## Validation
- After code changes, run at least a startup validation:
  - `godot461 --headless --path . --quit`
- For scene-entry smoke checks, use:
  - `godot461 --headless --path . --scene res://scenes/MainMenu.tscn --quit-after 30`
- If runtime/gameplay behavior changed, also perform a short manual scenario smoke test from MainMenu.

## Notes
- No automated test suite is currently established; rely on the validation workflow documented in `AGENTS.md`.
- Do not modify third-party addon internals unless explicitly requested.
