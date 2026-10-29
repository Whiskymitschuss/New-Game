#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${GODOT_BIN:=godot}"
mkdir -p builds
# Tests use a disposable profile; never mutate the player's local progression.
for suite in audio interface_motion combat_motion actor_rig blood_fx elemental_fx support_drone elemental_presentation horror_integration circuit_layout circuit_physics hero_gear reactor_switch special_ammo workshop forge_integration boss_supply first_second balance progression weapon_balance reactor run reuse ui_layout ux_flow campaign tier_campaign; do
  test_data=$(mktemp -d /tmp/deadwave-test-XXXXXXXX)
  if ! XDG_DATA_HOME="$test_data" "$GODOT_BIN" --headless --path . --fixed-fps 60 --script "res://tests/$suite.gd" > "builds/test-$suite.log" 2>&1; then
    cat "builds/test-$suite.log"
    exit 1
  fi
  cat "builds/test-$suite.log"
  if rg -q 'SCRIPT ERROR|Parse Error|FAIL:|Full run failed' "builds/test-$suite.log"; then exit 1; fi
  rm -rf "$test_data"
done
