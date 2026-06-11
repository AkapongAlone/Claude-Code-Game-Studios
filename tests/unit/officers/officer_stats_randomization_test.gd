extends "res://tests/helpers/test_case.gd"
## Officer Stats — generic officer recruitment randomization.
## Covers design/gdd/officer-stats.md acceptance criteria: stats within
## archetype baseline ± variance (clamped), invalid archetype → null,
## deterministic with a seeded RNG.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

## Warrior archetype per assets/data/officers.json: WAR baseline 78, Δ=3.
const WARRIOR_WAR_BASELINE := 78
const WARRIOR_VARIANCE := 3


## AC: 100 Warrior recruits → all WAR within [75, 81] and within [1, 100].
## (Pure ±3 randomization can never leave the window, so all 100 — stronger
## than the GDD's ≥70 floor.)
func test_warrior_recruits_war_within_variance_window() -> void:
	var registry := Fixtures.officer_registry()
	var rng := Fixtures.seeded_rng()
	for i in 100:
		var officer := registry.recruit_generic("warrior", rng)
		assert_not_null(officer)
		assert_between(officer.war(), WARRIOR_WAR_BASELINE - WARRIOR_VARIANCE, WARRIOR_WAR_BASELINE + WARRIOR_VARIANCE)
		assert_between(officer.war(), 1, 100)
		assert_false(officer.is_named, "generic recruits must not be named officers")


## Every stat of a recruit stays within its archetype baseline ± variance.
func test_all_recruit_stats_within_archetype_variance() -> void:
	var config := Fixtures.officers_config()
	var baseline: Dictionary = config["archetypes"]["scholar"]["stats"]
	var variance: int = int(config["archetypes"]["scholar"]["variance"])
	var registry := OfficerRegistry.from_config(config)
	var rng := Fixtures.seeded_rng()
	for i in 50:
		var officer := registry.recruit_generic("scholar", rng)
		for key: String in ["war", "ldr", "int", "pol", "chr"]:
			var value := officer.get_stat_by_name(key)
			var base := int(baseline[key])
			assert_between(value, base - variance, base + variance, "scholar %s outside baseline ± variance" % key)


## AC: invalid archetype → recruitment fails with null, no fallback assigned.
## (The push_error output below is EXPECTED noise from this test.)
func test_invalid_archetype_returns_null() -> void:
	var registry := Fixtures.officer_registry()
	assert_null(registry.recruit_generic("ninja_pirate", Fixtures.seeded_rng()))


## Determinism: identical seeds produce identical recruit stat blocks.
func test_recruitment_deterministic_with_same_seed() -> void:
	var first := Fixtures.officer_registry().recruit_generic("warrior", Fixtures.seeded_rng(42))
	var second := Fixtures.officer_registry().recruit_generic("warrior", Fixtures.seeded_rng(42))
	for stat: Officer.Stat in Officer.Stat.values():
		assert_eq(first.get_stat(stat), second.get_stat(stat), "same seed must give identical stats")


## AC (distribution): over many recruits the WAR roll covers the whole
## [baseline - Δ, baseline + Δ] window — no value is unreachable.
## (Lightweight proxy for the GDD's chi-square uniformity criterion.)
func test_randomization_covers_full_variance_range() -> void:
	var registry := Fixtures.officer_registry()
	var rng := Fixtures.seeded_rng()
	var seen: Dictionary = {}
	for i in 1000:
		var officer := registry.recruit_generic("warrior", rng)
		seen[officer.war()] = seen.get(officer.war(), 0) + 1
	for value in range(WARRIOR_WAR_BASELINE - WARRIOR_VARIANCE, WARRIOR_WAR_BASELINE + WARRIOR_VARIANCE + 1):
		assert_true(seen.has(value), "WAR value %d never rolled in 1000 recruits" % value)


## Clamping: an archetype whose baseline + variance exceeds 100 still
## produces stats within [1, 100] (clamped by construction).
func test_extreme_archetype_clamped_to_valid_range() -> void:
	var config := {
		"stat_min": 1,
		"stat_max": 100,
		"named_officers": [],
		"archetypes": {
			"titan": { "name": "Titan", "variance": 5, "stats": { "war": 98, "ldr": 2, "int": 50, "pol": 50, "chr": 50 } }
		}
	}
	var registry := OfficerRegistry.from_config(config)
	var rng := Fixtures.seeded_rng()
	for i in 100:
		var officer := registry.recruit_generic("titan", rng)
		assert_between(officer.war(), 1, 100, "WAR must clamp at 100")
		assert_between(officer.ldr(), 1, 100, "LDR must clamp at 1")
