extends "res://tests/helpers/test_case.gd"
## Victory/Defeat Conditions — design/gdd/victory-defeat-conditions.md
## acceptance criteria: route fraction math, inclusive thresholds,
## the 4-tier evaluation order, turn limit boundary, objectives.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

const BASIC_DEF := {
	"victory_conditions": [{ "type": "ROUTE_ENEMY", "threshold": 0.50 }],
	"defeat_conditions": [
		{ "type": "PLAYER_ROUTED", "threshold": 0.50 },
		{ "type": "EXCEED_TURN_LIMIT", "max_turns": 20 },
	],
	"victory_mode": "any",
}


func _squads_with_broken(side: Squad.Side, total_active: int, broken: int) -> Array:
	var squads: Array = []
	for i in total_active:
		var squad := Fixtures.battle_squad("%s_%d" % ["p" if side == Squad.Side.PLAYER else "e", i], side, Vector3i(i, -i, 0))
		if i < broken:
			squad.set_morale(0)
		squads.append(squad)
	return squads


## AC-01: 10 starting, 2 broken-on-map + 1 routed-off + 2 dead → 0.50.
func test_route_fraction_three_buckets() -> void:
	var checker := VictoryChecker.from_definition(BASIC_DEF, 5, 10)
	var squads := _squads_with_broken(Squad.Side.ENEMY, 7, 2)
	checker.record_rout_exit(Squad.Side.ENEMY)
	checker.record_death(Squad.Side.ENEMY)
	checker.record_death(Squad.Side.ENEMY)
	assert_almost_eq(checker.route_fraction(Squad.Side.ENEMY, squads), 0.5)


## AC-02: 3 dead of 8 starting → 0.375 — below threshold, no rout fires.
func test_route_fraction_below_threshold_no_fire() -> void:
	var checker := VictoryChecker.from_definition(BASIC_DEF, 5, 8)
	for i in 3:
		checker.record_death(Squad.Side.ENEMY)
	var squads := _squads_with_broken(Squad.Side.ENEMY, 5, 0) + _squads_with_broken(Squad.Side.PLAYER, 5, 0)
	var report := checker.evaluate(squads, 3)
	assert_eq(report.result, VictoryChecker.Result.ONGOING)


## AC-04: enemy route_fraction exactly 0.50 → ROUTE_ENEMY fires (inclusive).
func test_victory_threshold_inclusive() -> void:
	var checker := VictoryChecker.from_definition(BASIC_DEF, 4, 4)
	var enemies := _squads_with_broken(Squad.Side.ENEMY, 4, 2)
	var players := _squads_with_broken(Squad.Side.PLAYER, 4, 0)
	var report := checker.evaluate(enemies + players, 5)
	assert_eq(report.result, VictoryChecker.Result.VICTORY)
	assert_eq(report.trigger_type, "ROUTE_ENEMY")


## AC-06: player route_fraction exactly 0.50 → PLAYER_ROUTED fires.
func test_defeat_threshold_inclusive() -> void:
	var checker := VictoryChecker.from_definition(BASIC_DEF, 4, 4)
	var enemies := _squads_with_broken(Squad.Side.ENEMY, 4, 0)
	var players := _squads_with_broken(Squad.Side.PLAYER, 4, 2)
	var report := checker.evaluate(enemies + players, 5)
	assert_eq(report.result, VictoryChecker.Result.DEFEAT)
	assert_eq(report.trigger_type, "PLAYER_ROUTED")


## AC-11: mutual rout → VICTORY (victory checked before soft defeat).
func test_mutual_rout_is_pyrrhic_victory() -> void:
	var checker := VictoryChecker.from_definition(BASIC_DEF, 4, 4)
	var squads := _squads_with_broken(Squad.Side.ENEMY, 4, 2) + _squads_with_broken(Squad.Side.PLAYER, 4, 2)
	var report := checker.evaluate(squads, 5)
	assert_eq(report.result, VictoryChecker.Result.VICTORY)


## AC-08: LOSE_VIP + ROUTE_ENEMY same turn → DEFEAT (hard defeat first).
func test_lose_vip_precedes_victory() -> void:
	var definition := {
		"victory_conditions": [{ "type": "ROUTE_ENEMY", "threshold": 0.50 }],
		"defeat_conditions": [{ "type": "LOSE_VIP", "vip_officer_id": "kaster" }],
	}
	var checker := VictoryChecker.from_definition(definition, 4, 4)
	var vip := Fixtures.battle_squad("p_kaster", Squad.Side.PLAYER, Vector3i.ZERO,
		Fixtures.officer_registry().get_officer("kaster"))
	checker.register_officer_squad("kaster", vip)
	vip.hp = 0.0
	var squads := _squads_with_broken(Squad.Side.ENEMY, 4, 2) + [vip]
	var report := checker.evaluate(squads, 5)
	assert_eq(report.result, VictoryChecker.Result.DEFEAT)
	assert_eq(report.trigger_type, "LOSE_VIP")


## AC-15/16: turn limit is strictly greater-than.
func test_turn_limit_boundary() -> void:
	var checker := VictoryChecker.from_definition(BASIC_DEF, 4, 4)
	var squads := _squads_with_broken(Squad.Side.ENEMY, 4, 0) + _squads_with_broken(Squad.Side.PLAYER, 4, 0)
	assert_eq(checker.evaluate(squads, 20).result, VictoryChecker.Result.ONGOING, "turn == max does not fire")
	var report := checker.evaluate(squads, 21)
	assert_eq(report.result, VictoryChecker.Result.DEFEAT)
	assert_eq(report.trigger_type, "EXCEED_TURN_LIMIT")


## AC-12: victory is checked before the turn limit.
func test_victory_precedes_turn_limit() -> void:
	var checker := VictoryChecker.from_definition(BASIC_DEF, 4, 4)
	var squads := _squads_with_broken(Squad.Side.ENEMY, 4, 3) + _squads_with_broken(Squad.Side.PLAYER, 4, 0)
	var report := checker.evaluate(squads, 21)
	assert_eq(report.result, VictoryChecker.Result.VICTORY)


## AC-25: ELIMINATE_TARGET counts routing off-map as elimination.
func test_eliminate_target_via_off_map() -> void:
	var definition := {
		"victory_conditions": [{ "type": "ELIMINATE_TARGET", "target_squad_id": "e_lycurse" }],
		"defeat_conditions": [{ "type": "PLAYER_ROUTED", "threshold": 0.50 }],
	}
	var checker := VictoryChecker.from_definition(definition, 4, 4)
	var target := Fixtures.battle_squad("e_lycurse", Squad.Side.ENEMY, Vector3i.ZERO)
	checker.register_officer_squad("e_lycurse", target)
	target.is_off_map = true
	var squads: Array = [target] + _squads_with_broken(Squad.Side.PLAYER, 4, 0)
	var report := checker.evaluate(squads, 3)
	assert_eq(report.result, VictoryChecker.Result.VICTORY)
	assert_eq(report.trigger_type, "ELIMINATE_TARGET")


## victory_mode "all": one of two conditions met → no victory yet.
func test_victory_mode_all_requires_every_condition() -> void:
	var definition := {
		"victory_conditions": [
			{ "type": "ROUTE_ENEMY", "threshold": 0.50 },
			{ "type": "SURVIVE_TURNS", "target_turn": 10 },
		],
		"defeat_conditions": [{ "type": "EXCEED_TURN_LIMIT", "max_turns": 30 }],
		"victory_mode": "all",
	}
	var checker := VictoryChecker.from_definition(definition, 4, 4)
	var squads := _squads_with_broken(Squad.Side.ENEMY, 4, 3) + _squads_with_broken(Squad.Side.PLAYER, 4, 0)
	assert_eq(checker.evaluate(squads, 5).result, VictoryChecker.Result.ONGOING, "rout met but turn 5 < 10")
	assert_eq(checker.evaluate(squads, 10).result, VictoryChecker.Result.VICTORY, "both met at turn 10")


## AC-17/20: BROKEN squads do not control objectives; N consecutive turns
## of player control fire HOLD_OBJECTIVE.
func test_hold_objective_control_and_counter() -> void:
	var objective := { "q": 0, "r": 0 }
	var definition := {
		"victory_conditions": [{ "type": "HOLD_OBJECTIVE", "hex_coord": objective, "hold_turns": 2 }],
		"defeat_conditions": [{ "type": "EXCEED_TURN_LIMIT", "max_turns": 30 }],
	}
	var checker := VictoryChecker.from_definition(definition, 2, 2)
	var holder := Fixtures.battle_squad("holder", Squad.Side.PLAYER, Vector3i.ZERO)
	var squads: Array = [holder]
	checker.update_objectives(squads)
	assert_eq(checker.evaluate(squads, 1).result, VictoryChecker.Result.ONGOING, "1 of 2 turns held")
	checker.update_objectives(squads)
	assert_eq(checker.evaluate(squads, 2).result, VictoryChecker.Result.VICTORY)
	# BROKEN squad does not control: counter resets.
	var checker2 := VictoryChecker.from_definition(definition, 2, 2)
	holder.set_morale(0)
	checker2.update_objectives(squads)
	checker2.update_objectives(squads)
	assert_eq(checker2.evaluate(squads, 2).result, VictoryChecker.Result.ONGOING, "BROKEN squad cannot hold")


## Edge case: starting_squads = 0 → route_fraction defined as 1.0.
func test_zero_starting_squads_fraction_is_one() -> void:
	var checker := VictoryChecker.from_definition(BASIC_DEF, 4, 0)
	assert_almost_eq(checker.route_fraction(Squad.Side.ENEMY, []), 1.0)
