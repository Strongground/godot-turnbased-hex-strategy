#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
USER_DIR="${1:-/tmp/godot-turnbased-hex-strategy-userdata}"

mkdir -p "${USER_DIR}/config" "${USER_DIR}/data"

env \
	HOME="${USER_DIR}" \
	XDG_CONFIG_HOME="${USER_DIR}/config" \
	XDG_DATA_HOME="${USER_DIR}/data" \
	godot461 --headless --path "${PROJECT_ROOT}" --scene res://themes/example-modern/scenarios/scenario_1.tscn --quit-after 60
