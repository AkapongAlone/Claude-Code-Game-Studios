extends "res://tests/helpers/test_case.gd"
## Fog of War — design/gdd/fog-of-war.md acceptance criteria: vision range
## formula, distance/LOS gates, union visibility, state transitions, ghost
## staleness, ranged targeting constraint.

const Fixtures := preload("res://tests/helpers/fixtures.gd")


## AC 1–6: base vision by unit class; Hill +1; Forest adds nothing.
func test_vision_range_formula() -> void:
	var grid := Fixtures.grid_from_rows(["..hf", "...."])
	var fog := Fixtures.fog_of_war(grid)
	var inf := Fixtures.battle_squad("inf", Squad.Side.PLAYER, CubeHex.offset_to_cube(0, 0), null, "swordsman", grid)
	var li := Fixtures.battle_squad("li", Squad.Side.PLAYER, CubeHex.offset_to_cube(1, 0), null, "archer", grid)
	assert_eq(fog.vision_range(inf), 2, "INF base 2")
	assert_eq(fog.vision_range(li), 3, "LI base 3")
	var on_hill := Fixtures.battle_squad("hill", Squad.Side.PLAYER, CubeHex.offset_to_cube(2, 0), null, "swordsman", grid)
	assert_eq(fog.vision_range(on_hill), 3, "INF on Hill: 2 + 1")
	var in_forest := Fixtures.battle_squad("forest", Squad.Side.PLAYER, CubeHex.offset_to_cube(3, 0), null, "swordsman", grid)
	assert_eq(fog.vision_range(in_forest), 2, "Forest adds no vision")


## AC 8 equivalent: passive bonus stacks additively (Hill + bonus).
func test_vision_bonus_stacks() -> void:
	var grid := Fixtures.grid_from_rows(["h"])
	var fog := Fixtures.fog_of_war(grid)
	var squad := Fixtures.battle_squad("s", Squad.Side.PLAYER, CubeHex.offset_to_cube(0, 0), null, "swordsman", grid)
	squad.vision_bonus = 1
	assert_eq(fog.vision_range(squad), 4, "2 base + 1 hill + 1 bonus")


## AC 9–11: range boundary is inclusive (<=); one hex beyond fails.
func test_visibility_distance_boundary() -> void:
	var grid := Fixtures.grid_from_rows(["......"])
	var fog := Fixtures.fog_of_war(grid)
	var watcher := Fixtures.battle_squad("w", Squad.Side.PLAYER, CubeHex.offset_to_cube(0, 0), null, "archer", grid)
	var at_three := Fixtures.battle_squad("e3", Squad.Side.ENEMY, CubeHex.offset_to_cube(3, 0), null, "swordsman", grid)
	var at_four := Fixtures.battle_squad("e4", Squad.Side.ENEMY, CubeHex.offset_to_cube(5, 0), null, "swordsman", grid)
	assert_true(fog.is_visible(at_three, [watcher]), "LI vision 3 sees distance 3 (inclusive)")
	assert_false(fog.is_visible(at_four, [watcher]), "distance 5 beyond range")


## AC 12/16: Forest blocks one watcher's LOS, but the union of squads wins.
func test_visibility_union_across_squads() -> void:
	var grid := Fixtures.grid_from_rows([".f.", "..."])
	var fog := Fixtures.fog_of_war(grid)
	var blocked := Fixtures.battle_squad("blocked", Squad.Side.PLAYER, CubeHex.offset_to_cube(0, 0), null, "archer", grid)
	var enemy := Fixtures.battle_squad("enemy", Squad.Side.ENEMY, CubeHex.offset_to_cube(2, 1), null, "swordsman", grid)
	assert_false(fog.is_visible(enemy, [blocked]), "forest blocks the only watcher")
	var clear := Fixtures.battle_squad("clear", Squad.Side.PLAYER, CubeHex.offset_to_cube(1, 1), null, "archer", grid)
	assert_true(fog.is_visible(enemy, [blocked, clear]), "one clear LOS suffices")


## AC 18–21/28: state transitions — HIDDEN start, VISIBLE on sight,
## PREVIOUSLY_SEEN ghost stays at the last known position.
func test_state_transitions_and_ghost() -> void:
	var grid := Fixtures.grid_from_rows(["........"])
	var fog := Fixtures.fog_of_war(grid)
	var watcher := Fixtures.battle_squad("w", Squad.Side.PLAYER, CubeHex.offset_to_cube(0, 0), null, "archer", grid)
	var enemy := Fixtures.battle_squad("e", Squad.Side.ENEMY, CubeHex.offset_to_cube(7, 0), null, "swordsman", grid)
	fog.initialize([watcher], [enemy])
	assert_eq(enemy.visibility_state, Squad.Visibility.HIDDEN, "AC 28: enemies start HIDDEN")
	# Enemy moves into range → VISIBLE.
	grid.relocate_squad(enemy, CubeHex.offset_to_cube(2, 0))
	fog.recalculate([watcher], [enemy], 2)
	assert_eq(enemy.visibility_state, Squad.Visibility.VISIBLE)
	assert_eq(enemy.last_known_position, CubeHex.offset_to_cube(2, 0))
	# Enemy retreats into the dark → PREVIOUSLY_SEEN; ghost does not follow.
	grid.relocate_squad(enemy, CubeHex.offset_to_cube(7, 0))
	fog.recalculate([watcher], [enemy], 3)
	assert_eq(enemy.visibility_state, Squad.Visibility.PREVIOUSLY_SEEN)
	assert_eq(enemy.last_known_position, CubeHex.offset_to_cube(2, 0), "AC 19: ghost stays at last sighting")
	# Re-sighted → VISIBLE again.
	grid.relocate_squad(enemy, CubeHex.offset_to_cube(3, 0))
	fog.recalculate([watcher], [enemy], 4)
	assert_eq(enemy.visibility_state, Squad.Visibility.VISIBLE)


## AC 22–24: staleness badge at >= 3 turns since last sighting.
func test_ghost_staleness_threshold() -> void:
	var grid := Fixtures.grid_from_rows(["..."])
	var fog := Fixtures.fog_of_war(grid)
	var enemy := Fixtures.battle_squad("e", Squad.Side.ENEMY, CubeHex.offset_to_cube(0, 0), null, "swordsman", grid)
	enemy.visibility_state = Squad.Visibility.PREVIOUSLY_SEEN
	enemy.last_seen_turn = 4
	assert_false(fog.is_stale(enemy, 6), "staleness 2 < 3: no badge")
	assert_true(fog.is_stale(enemy, 7), "staleness 3: badge shown")


## AC 29: battle_start_reveals force squads VISIBLE at battle start.
func test_battle_start_reveals() -> void:
	var grid := Fixtures.grid_from_rows(["........"])
	var fog := Fixtures.fog_of_war(grid)
	var watcher := Fixtures.battle_squad("w", Squad.Side.PLAYER, CubeHex.offset_to_cube(0, 0), null, "swordsman", grid)
	var scouted := Fixtures.battle_squad("scouted", Squad.Side.ENEMY, CubeHex.offset_to_cube(7, 0), null, "swordsman", grid)
	fog.initialize([watcher], [scouted], ["scouted"])
	assert_eq(scouted.visibility_state, Squad.Visibility.VISIBLE, "pre-battle scouting reveals")


## AC 31–33: only VISIBLE enemies can be ranged-targeted.
func test_ranged_targeting_constraint() -> void:
	var grid := Fixtures.grid_from_rows(["..."])
	var fog := Fixtures.fog_of_war(grid)
	var enemy := Fixtures.battle_squad("e", Squad.Side.ENEMY, CubeHex.offset_to_cube(0, 0), null, "swordsman", grid)
	enemy.visibility_state = Squad.Visibility.VISIBLE
	assert_true(fog.can_target(enemy))
	enemy.visibility_state = Squad.Visibility.PREVIOUSLY_SEEN
	assert_false(fog.can_target(enemy), "ghosts cannot be targeted")
	enemy.visibility_state = Squad.Visibility.HIDDEN
	assert_false(fog.can_target(enemy))
