extends "res://tests/helpers/test_case.gd"
## BattleController integration smoke test — loads the shipping demo battle
## (assets/data/battles/open_field_demo.json) and plays several full rounds
## headlessly. Verifies the playable loop holds together: setup, movement,
## AI, combat, morale, routing, fog, and victory evaluation all run without
## breaking invariants.

const Fixtures := preload("res://tests/helpers/fixtures.gd")


func test_demo_battle_loads_with_full_roster() -> void:
	var controller := BattleController.load_battle(Fixtures.battle_definition(), Fixtures.seeded_rng())
	assert_eq(controller.squads.size(), 10, "5 player + 5 enemy squads")
	assert_eq(controller.side_squads(Squad.Side.PLAYER).size(), 5)
	assert_eq(controller.side_squads(Squad.Side.ENEMY).size(), 5)
	assert_eq(controller.current_turn, 1)
	assert_false(controller.battle_over)
	for squad: Squad in controller.squads:
		assert_true(squad.ap_pool >= 2 and squad.ap_pool <= 7, "AP pool in [2,7] for %s" % squad.id)
		assert_between(squad.facing_direction, 0, 5)
		assert_true(squad.morale == 100 or squad.morale == 70)
		assert_not_null(squad.tile, "every squad sits on a tile")


func test_kaster_squad_has_named_officer_stats() -> void:
	var controller := BattleController.load_battle(Fixtures.battle_definition(), Fixtures.seeded_rng())
	var kaster_squad: Squad = null
	for squad: Squad in controller.squads:
		if squad.id == "p_kaster":
			kaster_squad = squad
	assert_not_null(kaster_squad)
	assert_eq(kaster_squad.officer.war(), 82)
	assert_eq(kaster_squad.ap_pool, 5, "INF base 3 + LDR 96 bonus 2 = 5")


func test_player_move_consumes_ap_and_sets_flags() -> void:
	var controller := BattleController.load_battle(Fixtures.battle_definition(), Fixtures.seeded_rng())
	var squad: Squad = controller.side_squads(Squad.Side.PLAYER)[0]
	var reachable := controller.reachable_for(squad)
	assert_false(reachable.is_empty(), "fresh squad must have somewhere to go")
	var destination: Vector3i = reachable.keys()[0]
	var cost: int = reachable[destination]
	var ap_before := squad.ap_remaining
	assert_true(controller.move_squad(squad, destination))
	assert_eq(squad.position, destination)
	assert_eq(squad.ap_remaining, ap_before - cost)
	assert_true(squad.moved_this_turn)
	assert_false(controller.move_squad(squad, squad.position + CubeHex.DIRECTIONS[0]), "one move per turn")


func test_three_full_rounds_run_without_breaking_invariants() -> void:
	var controller := BattleController.load_battle(Fixtures.battle_definition(), Fixtures.seeded_rng())
	for round_index in 3:
		if controller.battle_over:
			break
		controller.end_player_turn()
	assert_true(controller.battle_over or controller.current_turn == 4, "turn advanced through 3 rounds")
	for squad: Squad in controller.squads:
		assert_between(squad.morale, 0, 100, "morale stays in [0,100] for %s" % squad.id)
		assert_true(squad.hp >= 0.0, "hp never negative for %s" % squad.id)
		if squad.is_active():
			assert_true(controller.grid.squad_at(squad.position) == squad, "grid occupancy consistent for %s" % squad.id)


func test_field_duel_between_adjacent_officers() -> void:
	var controller := BattleController.load_battle(Fixtures.battle_definition(), Fixtures.seeded_rng())
	# Teleport Alexsen's squad adjacent to Lycurse's squad for the duel.
	var alexsen: Squad = null
	var lycurse: Squad = null
	for squad: Squad in controller.squads:
		if squad.id == "p_alexsen":
			alexsen = squad
		elif squad.id == "e_lycurse":
			lycurse = squad
	controller.grid.relocate_squad(alexsen, lycurse.position + CubeHex.DIRECTIONS[3])
	var engine := controller.start_field_duel(alexsen, lycurse)
	assert_not_null(engine, "adjacent officers can duel")
	assert_true(controller.duel_active, "tactical layer frozen during duel")
	assert_eq(engine.p1.attack_damage, 14, "Alexsen WAR 98 → 14")
	assert_eq(engine.p2.attack_damage, 14, "Lycurse WAR 92 → 14")
	# Resolve the duel quickly: drain Lycurse and finish.
	engine.p2.resolve = 5
	engine.resolve_turn(DuelEngine.Stance.ATTACK, DuelEngine.Stance.FEINT)
	assert_eq(engine.outcome, DuelEngine.Outcome.VICTORY)
	var enemy_morale_before := lycurse.morale
	controller.finish_field_duel(engine, alexsen, lycurse)
	assert_false(controller.duel_active)
	assert_null(lycurse.officer, "losing officer incapacitated — squad now officer-less")
	assert_eq(lycurse.morale, clampi(enemy_morale_before - 25, 0, 100), "loser squad -25 morale")
	assert_null(controller.start_field_duel(alexsen, lycurse), "once per battle per challenger")
