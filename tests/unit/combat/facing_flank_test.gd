extends "res://tests/helpers/test_case.gd"
## Facing & Flank formulas — design/gdd/facing-and-flank.md acceptance
## criteria: facing updates, the (R − D + 6) mod 6 arc check, wrap-around,
## and the forest ambush override.

const Fixtures := preload("res://tests/helpers/fixtures.gd")


## AC: move East (+1,−1,0) → facing 0; move NE (0,−1,+1) → facing 5.
func test_facing_from_move_canonical_vectors() -> void:
	assert_eq(FacingSystem.facing_from_move(Vector3i(0, 0, 0), Vector3i(1, -1, 0)), 0)
	assert_eq(FacingSystem.facing_from_move(Vector3i(0, 0, 0), Vector3i(0, -1, 1)), 5)


## AC: attack without move → facing toward the target.
func test_facing_toward_attack_target() -> void:
	var origin := Vector3i(0, 0, 0)
	var target := CubeHex.neighbor(origin, 2)
	assert_eq(FacingSystem.facing_toward(origin, target), 2)


## AC: forward arc — relative_dir 0, 1, 2 are frontal (no flank).
func test_forward_arc_not_flanking() -> void:
	assert_false(FacingSystem.is_flank_direction(0, 0), "relative 0")
	assert_false(FacingSystem.is_flank_direction(0, 1), "relative 1")
	assert_false(FacingSystem.is_flank_direction(0, 2), "relative 2 — boundary (a >= 2 bug fails here)")


## AC: flank arc — relative_dir 3, 4, 5 are flanking.
func test_flank_arc_directions() -> void:
	assert_true(FacingSystem.is_flank_direction(0, 3), "directly behind")
	assert_true(FacingSystem.is_flank_direction(0, 4))
	assert_true(FacingSystem.is_flank_direction(0, 5))


## AC: wrap-around — D=5, R=2 → relative (2−5+6) mod 6 = 3 → flanking.
func test_flank_wraparound_arithmetic() -> void:
	assert_true(FacingSystem.is_flank_direction(5, 2))


## GDD Formula 2 example: D=1 (SE), R=4 (NW) → relative 3 → flank.
func test_flank_gdd_worked_example() -> void:
	assert_true(FacingSystem.is_flank_direction(1, 4))
	assert_false(FacingSystem.is_flank_direction(1, 2), "frontal example: relative 1")


## AC: forest ambush fires only when attacker is stationary in forest AND
## the target moved this turn.
func test_forest_ambush_condition_table() -> void:
	assert_true(FacingSystem.is_forest_ambush(true, false, true), "all conditions met")
	assert_false(FacingSystem.is_forest_ambush(true, true, true), "attacker moved — fails")
	assert_false(FacingSystem.is_forest_ambush(true, false, false), "target stationary — fails")
	assert_false(FacingSystem.is_forest_ambush(false, false, true), "not in forest — fails")


## AC: ambush overrides a frontal facing result in the full check.
func test_is_flanking_ambush_overrides_frontal() -> void:
	var defender := Fixtures.battle_squad("def", Squad.Side.ENEMY, Vector3i(0, 0, 0))
	defender.facing_direction = 0
	defender.moved_this_turn = true
	# Attacker directly in front (direction 0 from defender) — frontal angle.
	var attacker := Fixtures.battle_squad("att", Squad.Side.PLAYER, CubeHex.neighbor(Vector3i(0, 0, 0), 0))
	attacker.moved_this_turn = false
	assert_false(FacingSystem.is_flanking(attacker, defender, false), "frontal without forest")
	assert_true(FacingSystem.is_flanking(attacker, defender, true), "forest ambush overrides")


## AC: facing-based flank in the full check (attacker behind defender).
func test_is_flanking_from_behind() -> void:
	var defender := Fixtures.battle_squad("def", Squad.Side.ENEMY, Vector3i(0, 0, 0))
	defender.facing_direction = 0
	var attacker := Fixtures.battle_squad("att", Squad.Side.PLAYER, CubeHex.neighbor(Vector3i(0, 0, 0), 3))
	assert_true(FacingSystem.is_flanking(attacker, defender, false))


## AC battle-start initialization: default facing points toward the
## nearest enemy cluster.
func test_default_facing_toward_nearest_enemy() -> void:
	var east_enemy: Array = [Vector3i(4, -4, 0), Vector3i(-3, 3, 0)]
	# Nearest is West (-3,3,0) at distance 3 vs 4 → facing 3 (West).
	assert_eq(FacingSystem.default_facing(Vector3i(0, 0, 0), east_enemy), 3)
	assert_eq(FacingSystem.default_facing(Vector3i(0, 0, 0), []), 0, "no enemies → East fallback")
