extends "res://tests/helpers/test_case.gd"
## Duel Engine — design/gdd/duel-system.md acceptance criteria:
## F-1/2/3 stat derivation, F-4 derived damages, the full RPS table,
## stamina constraints, Crushing Blow, Read gating, termination, Yield.

const Fixtures := preload("res://tests/helpers/fixtures.gd")


## Alexsen (WAR 98 CHR 75 INT 40) vs Kaster (WAR 82 CHR 88 INT 92).
func _fresh() -> DuelEngine:
	var engine := Fixtures.duel_engine()
	var registry := Fixtures.officer_registry()
	engine.start(registry.get_officer("alexsen"), registry.get_officer("kaster"))
	return engine


## AC 1–4: resolve = floor(CHR/2) + 40 (Kaster 84, floor 40, ceiling 90,
## named officer table).
func test_resolve_formula() -> void:
	var engine := Fixtures.duel_engine()
	assert_eq(engine.make_participant(Fixtures.make_officer("x", 50, 50, 50, 50, 88)).max_resolve, 84)
	assert_eq(engine.make_participant(Fixtures.make_officer("x", 50, 50, 50, 50, 1)).max_resolve, 40)
	assert_eq(engine.make_participant(Fixtures.make_officer("x", 50, 50, 50, 50, 100)).max_resolve, 90)
	var registry := Fixtures.officer_registry()
	assert_eq(engine.make_participant(registry.get_officer("alexsen")).max_resolve, 77)
	assert_eq(engine.make_participant(registry.get_officer("thane")).max_resolve, 62)
	assert_eq(engine.make_participant(registry.get_officer("zhuge_jian")).max_resolve, 80)


## AC 5–6: stamina = floor(INT/10) + 5 (Zhuge/Kaster/Bon all 14; INT 1 → 5).
func test_stamina_formula() -> void:
	var engine := Fixtures.duel_engine()
	var registry := Fixtures.officer_registry()
	assert_eq(engine.make_participant(registry.get_officer("zhuge_jian")).stamina, 14)
	assert_eq(engine.make_participant(registry.get_officer("kaster")).stamina, 14)
	assert_eq(engine.make_participant(registry.get_officer("alexsen")).stamina, 9)
	assert_eq(engine.make_participant(Fixtures.make_officer("x", 50, 50, 1, 50, 50)).stamina, 5)


## AC 7: attack = floor(WAR/10) + 5 (Alexsen 14, Kaster 13).
func test_attack_damage_formula() -> void:
	var engine := Fixtures.duel_engine()
	var registry := Fixtures.officer_registry()
	assert_eq(engine.make_participant(registry.get_officer("alexsen")).attack_damage, 14)
	assert_eq(engine.make_participant(registry.get_officer("kaster")).attack_damage, 13)


## AC 8–10: derived damages — counter ceil(14×0.4)=6, feint ceil(13×0.6)=8,
## tie floor(×0.5).
func test_derived_damage_values() -> void:
	var engine := Fixtures.duel_engine()
	assert_eq(engine.counter_damage(14), 6)
	assert_eq(engine.feint_break_damage(13), 8)
	assert_eq(engine.tie_attack_damage(14), 7)
	assert_eq(engine.tie_attack_damage(13), 6)


## AC 11 + AC 10: full RPS table. P1 = Alexsen (atk 14), P2 = Kaster (atk 13).
## Attack/Attack tie: each takes the OTHER's halved attack.
func test_stance_resolution_table() -> void:
	var cases := [
		# [p1 stance, p2 stance, dmg to p1, dmg to p2]
		[DuelEngine.Stance.ATTACK, DuelEngine.Stance.ATTACK, 6, 7],
		[DuelEngine.Stance.ATTACK, DuelEngine.Stance.DEFEND, 6, 0],
		[DuelEngine.Stance.ATTACK, DuelEngine.Stance.FEINT, 0, 14],
		[DuelEngine.Stance.DEFEND, DuelEngine.Stance.ATTACK, 0, 6],
		[DuelEngine.Stance.DEFEND, DuelEngine.Stance.DEFEND, 0, 0],
		[DuelEngine.Stance.DEFEND, DuelEngine.Stance.FEINT, 8, 0],
		[DuelEngine.Stance.FEINT, DuelEngine.Stance.ATTACK, 13, 0],
		[DuelEngine.Stance.FEINT, DuelEngine.Stance.DEFEND, 0, 9],
		[DuelEngine.Stance.FEINT, DuelEngine.Stance.FEINT, 0, 0],
	]
	for case: Array in cases:
		var engine := _fresh()
		var result := engine.resolve_turn(case[0], case[1])
		assert_eq(result.damage_to_p1, case[2], "dmg to P1 for %s/%s" % [case[0], case[1]])
		assert_eq(result.damage_to_p2, case[3], "dmg to P2 for %s/%s" % [case[0], case[1]])


## AC 12–15: stance availability by stamina.
func test_stamina_availability_table() -> void:
	var engine := _fresh()
	engine.p1.stamina = 4
	var available := engine.available_stances(engine.p1)
	assert_true(available.has(DuelEngine.Stance.ATTACK))
	assert_true(available.has(DuelEngine.Stance.SIGNATURE), "stamina 4 = exact Crushing Blow cost — available")
	engine.p1.stamina = 3
	available = engine.available_stances(engine.p1)
	assert_true(available.has(DuelEngine.Stance.ATTACK))
	assert_false(available.has(DuelEngine.Stance.SIGNATURE), "cost 4 locked at stamina 3")
	engine.p1.stamina = 1
	available = engine.available_stances(engine.p1)
	assert_false(available.has(DuelEngine.Stance.ATTACK), "Attack costs 2")
	assert_true(available.has(DuelEngine.Stance.FEINT))
	assert_true(available.has(DuelEngine.Stance.DEFEND))
	engine.p1.stamina = 0
	available = engine.available_stances(engine.p1)
	assert_eq(available.size(), 1, "Exhaustion: Defend only")
	assert_true(available.has(DuelEngine.Stance.DEFEND))


## AC 16: stamina costs — Attack 2, Defend 1, Feint 1, Crushing Blow 4.
func test_stamina_costs_deducted() -> void:
	var engine := _fresh()
	engine.resolve_turn(DuelEngine.Stance.ATTACK, DuelEngine.Stance.DEFEND)
	assert_eq(engine.p1.stamina, 9 - 2)
	assert_eq(engine.p2.stamina, 14 - 1)
	var engine2 := _fresh()
	engine2.resolve_turn(DuelEngine.Stance.SIGNATURE, DuelEngine.Stance.FEINT)
	assert_eq(engine2.p1.stamina, 9 - 4, "Crushing Blow costs 4")


## AC 20–22: Crushing Blow overrides — bypasses Defend (full 14, no
## counter), vs Feint ceil(14×0.75)=11, head-on vs Attack both take full.
func test_crushing_blow_resolution() -> void:
	var vs_defend := _fresh().resolve_turn(DuelEngine.Stance.SIGNATURE, DuelEngine.Stance.DEFEND)
	assert_eq(vs_defend.damage_to_p2, 14, "bypasses the parry")
	assert_eq(vs_defend.damage_to_p1, 0, "no counter damage")
	var vs_feint := _fresh().resolve_turn(DuelEngine.Stance.SIGNATURE, DuelEngine.Stance.FEINT)
	assert_eq(vs_feint.damage_to_p2, 11)
	var vs_attack := _fresh().resolve_turn(DuelEngine.Stance.SIGNATURE, DuelEngine.Stance.ATTACK)
	assert_eq(vs_attack.damage_to_p2, 14, "full damage on collision")
	assert_eq(vs_attack.damage_to_p1, int(ceil(13 * 0.75)), "Alexsen absorbs reduced counter")


## AC 23: Crushing Blow is once per duel.
func test_signature_once_per_duel() -> void:
	var engine := _fresh()
	engine.resolve_turn(DuelEngine.Stance.SIGNATURE, DuelEngine.Stance.DEFEND)
	assert_false(engine.available_stances(engine.p1).has(DuelEngine.Stance.SIGNATURE))


## AC 17–19: Read fires on turn 3 for the strictly higher-WAR side only.
func test_read_gating() -> void:
	var engine := _fresh()
	engine.resolve_turn(DuelEngine.Stance.DEFEND, DuelEngine.Stance.DEFEND)
	engine.resolve_turn(DuelEngine.Stance.DEFEND, DuelEngine.Stance.DEFEND)
	assert_eq(engine.current_turn, 3)
	assert_true(engine.read_fires_for(engine.p1, engine.p2), "Alexsen WAR 98 > Kaster 82")
	assert_false(engine.read_fires_for(engine.p2, engine.p1), "lower WAR never reads")
	engine.resolve_turn(DuelEngine.Stance.DEFEND, DuelEngine.Stance.DEFEND)
	assert_eq(engine.current_turn, 4)
	assert_false(engine.read_fires_for(engine.p1, engine.p2), "turn 4: no read")
	# Equal WAR: no read for either side.
	var even := Fixtures.duel_engine()
	even.start(Fixtures.make_officer("a", 80, 50, 50, 50, 50), Fixtures.make_officer("b", 80, 50, 50, 50, 50))
	even.current_turn = 3
	assert_false(even.read_fires_for(even.p1, even.p2))
	assert_false(even.read_fires_for(even.p2, even.p1))


## Read hint accuracy: 1.0 always shows the true stance; 0.0 never does.
func test_read_hint_accuracy_extremes() -> void:
	var always := Fixtures.duel_engine({ "read_accuracy": 1.0 })
	var never := Fixtures.duel_engine({ "read_accuracy": 0.0 })
	var rng := Fixtures.seeded_rng()
	for i in 20:
		assert_eq(always.roll_read_hint(DuelEngine.Stance.FEINT, rng), DuelEngine.Stance.FEINT)
		assert_ne(never.roll_read_hint(DuelEngine.Stance.FEINT, rng), DuelEngine.Stance.FEINT)


## AC 24: resolve ≤ 0 ends the duel with the survivor as victor.
func test_resolve_depleted_terminates() -> void:
	var engine := _fresh()
	engine.p2.resolve = 5
	var result := engine.resolve_turn(DuelEngine.Stance.ATTACK, DuelEngine.Stance.FEINT)
	assert_eq(result.outcome, DuelEngine.Outcome.VICTORY)


## AC 25: both at ≤ 0 on the same turn → draw (mutual defeat).
func test_mutual_resolve_depletion_is_draw() -> void:
	var engine := _fresh()
	engine.p1.resolve = 5
	engine.p2.resolve = 5
	var result := engine.resolve_turn(DuelEngine.Stance.ATTACK, DuelEngine.Stance.ATTACK)
	assert_eq(result.outcome, DuelEngine.Outcome.DRAW)


## AC 26: mutual exhaustion → Final Exchange → higher resolve wins.
func test_mutual_exhaustion_final_exchange() -> void:
	var engine := _fresh()
	engine.p1.stamina = 1
	engine.p2.stamina = 1
	engine.p1.resolve = 50
	engine.p2.resolve = 30
	var result := engine.resolve_turn(DuelEngine.Stance.FEINT, DuelEngine.Stance.FEINT)
	assert_eq(result.outcome, DuelEngine.Outcome.VICTORY, "higher resolve wins the exchange")
	var tie := _fresh()
	tie.p1.stamina = 1
	tie.p2.stamina = 1
	tie.p1.resolve = 40
	tie.p2.resolve = 40
	assert_eq(tie.resolve_turn(DuelEngine.Stance.FEINT, DuelEngine.Stance.FEINT).outcome, DuelEngine.Outcome.DRAW)


## AC 27–28 + E-09: Yield availability at resolve ≤ 30% of max (inclusive).
func test_yield_threshold_inclusive() -> void:
	var engine := _fresh()
	engine.p2.resolve = int(engine.p2.max_resolve * 0.30)
	assert_true(engine.yield_available())
	engine.p2.resolve = int(engine.p2.max_resolve * 0.30) + 1
	assert_false(engine.yield_available())


## AC 30–31: intentional miss voids AI damage but stamina is still paid.
func test_intentional_miss_voids_damage() -> void:
	var engine := _fresh()
	engine.ai_behavior = "intentional_miss"
	engine.miss_frequency = 1.0
	var rng := Fixtures.seeded_rng()
	# P2 Attack beats P1 Feint — would deal 13, but the miss voids it.
	var result := engine.resolve_turn(DuelEngine.Stance.FEINT, DuelEngine.Stance.ATTACK, rng)
	assert_eq(result.damage_to_p1, 0, "miss_frequency 1.0 always voids")
	assert_eq(engine.p2.stamina, 14 - 2, "stamina cost paid despite the miss")
