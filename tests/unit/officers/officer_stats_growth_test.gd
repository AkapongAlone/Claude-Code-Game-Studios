extends "res://tests/helpers/test_case.gd"
## Officer Stats — act-transition growth.
## Covers design/gdd/officer-stats.md acceptance criteria: exact growth
## application, clamping at 100, deferral during battle, generics never grow.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

## Boundary-value fixture: a named officer already at/near the stat cap.
const MAXED_CONFIG := {
	"stat_min": 1,
	"stat_max": 100,
	"named_officers": [
		{ "id": "maxed", "name": "Maxed", "war": 99, "ldr": 50, "int": 50, "pol": 100, "chr": 50 }
	],
	"archetypes": {}
}


## AC: Kaster WAR 82, growth +2 specified → exactly 84 (no randomness in application).
func test_growth_plus_two_applies_exactly() -> void:
	var registry := Fixtures.officer_registry()
	registry.apply_act_growth([
		{ "officer_id": "kaster", "stat": Officer.Stat.WAR, "amount": 2 }
	])
	assert_eq(registry.get_officer("kaster").war(), 84)


## AC: POL at 100, growth +1 → remains 100 (clamped, not 101).
func test_growth_clamped_at_100() -> void:
	var registry := OfficerRegistry.from_config(MAXED_CONFIG)
	registry.apply_act_growth([
		{ "officer_id": "maxed", "stat": Officer.Stat.POL, "amount": 1 },
		{ "officer_id": "maxed", "stat": Officer.Stat.WAR, "amount": 3 }
	])
	var maxed := registry.get_officer("maxed")
	assert_eq(maxed.pol(), 100, "100 + 1 must clamp to 100")
	assert_eq(maxed.war(), 100, "99 + 3 must clamp to 100")


## AC: act transition during active battle → growth deferred until battle ends.
func test_growth_during_battle_deferred_until_end() -> void:
	var registry := Fixtures.officer_registry()
	registry.begin_battle()
	registry.apply_act_growth([
		{ "officer_id": "kaster", "stat": Officer.Stat.WAR, "amount": 2 }
	])
	assert_eq(registry.get_officer("kaster").war(), 82, "stats must not change mid-battle")
	registry.end_battle()
	assert_eq(registry.get_officer("kaster").war(), 84, "deferred growth applies after battle")


## GDD: generic officers do not grow.
## (The push_error output below is EXPECTED noise from this test.)
func test_generic_officer_growth_rejected() -> void:
	var registry := Fixtures.officer_registry()
	var generic := registry.recruit_generic("warrior", Fixtures.seeded_rng())
	assert_not_null(generic)
	var war_before := generic.war()
	registry.apply_act_growth([
		{ "officer_id": generic.id, "stat": Officer.Stat.WAR, "amount": 3 }
	])
	assert_eq(generic.war(), war_before, "generic officer stats must not grow")


## AC (post-growth invariant): after a full growth plan, every stat of every
## officer is still within [1, 100].
func test_all_stats_valid_after_act_growth() -> void:
	var registry := Fixtures.officer_registry()
	var rng := Fixtures.seeded_rng()
	var plan: Array = []
	for officer: Officer in registry.get_all_officers():
		for stat: Officer.Stat in Officer.Stat.values():
			plan.append({ "officer_id": officer.id, "stat": stat, "amount": OfficerRegistry.roll_growth(rng) })
	registry.apply_act_growth(plan)
	for officer: Officer in registry.get_all_officers():
		for stat: Officer.Stat in Officer.Stat.values():
			assert_between(officer.get_stat(stat), 1, 100, "%s %s out of range after growth" % [officer.id, Officer.Stat.keys()[stat]])


## GDD formula: stat_growth = random(1, 3) — rolls always land in [1, 3].
func test_roll_growth_always_within_one_to_three() -> void:
	var rng := Fixtures.seeded_rng()
	for i in 200:
		assert_between(OfficerRegistry.roll_growth(rng), 1, 3)
