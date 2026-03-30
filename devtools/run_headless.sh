#!/usr/bin/env bash
set -euo pipefail

# Headless smoke check for the default gameplay scene.
# Usage: bash devtools/run_headless.sh

HOME=/tmp XDG_DATA_HOME=/tmp XDG_CONFIG_HOME=/tmp /usr/local/bin/godot461 \
  --headless \
  --path . \
  --scene res://scenes/map_godot4.tscn \
  --quit-after 30
