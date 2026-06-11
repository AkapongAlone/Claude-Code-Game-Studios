extends "res://tests/helpers/test_case.gd"
## Combat Resolution — damage formulas (1–3).
## Covers design/gdd/combat-resolution.md acceptance criteria: ranged/melee
## base damage, terrain/flank/morale modifiers, 90 damage cap, and the
## safety fallbacks for bad terrain/flank inputs.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _resolver: CombatResolver


func setup() -> void:
	_resolver = Fixtures.combat_resolver()


## AC: archer (base 20) with WAR 80 on flat terrain → 20 × 1.8 = 36.
func test_archer_war80_flat_terrain_deals_36() -> void:
	var base := _resolver.base_damage_ranged(20, 80)
	assert_almost_eq(base, 36.0)
	assert_almost_eq(_resolver.total_damage(base, 1.0, 1.0, 1.0), 36.0)


## AC: same archer firing from a Hill (+25%) → 45.
func test_archer_from_hill_deals_45() -> void:
	assert_almost_eq(_resolver.total_damage(36.0, 1.25, 1.0, 1.0), 45.0)


## AC: same archer vs target in Forest (-25% cover) → 27.
func test_archer_versus_forest_target_deals_27() -> void:
	assert_almost_eq(_resolver.total_damage(36.0, 0.75, 1.0, 1.0), 27.0)


## AC: same archer flanking (+30%) → 46.8.
func test_archer_flanking_deals_46_8() -> void:
	assert_almost_eq(_resolver.total_damage(36.0, 1.0, 1.3, 1.0), 46.8)


## GDD formula 2 example: swordsman (base 40) with WAR 80 → 40 × 1.4 = 56.
func test_swordsman_war80_deals_56() -> void:
	assert_almost_eq(_resolver.base_damage_melee(40, 80), 56.0)


## Melee WAR scaling is dampened (÷200): same WAR adds half the multiplier.
func test_melee_war_scaling_half_of_ranged() -> void:
	assert_almost_eq(_resolver.base_damage_ranged(20, 100), 40.0, 0.0001, "ranged: 20 × 2.0")
	assert_almost_eq(_resolver.base_damage_melee(20, 100), 30.0, 0.0001, "melee: 20 × 1.5")


## GDD formula 3 example: 56 base × 1.25 hill × 1.3 flank = 91 → capped at 90.
func test_damage_capped_at_90() -> void:
	assert_almost_eq(_resolver.total_damage(56.0, 1.25, 1.3, 1.0), 90.0)


## AC: attacker morale broken → damage × 0.5.
func test_broken_attacker_deals_half_damage() -> void:
	assert_almost_eq(_resolver.total_damage(36.0, 1.0, 1.0, 0.5), 18.0)


## GDD edge case: terrain modifier 0 (no terrain assigned) → fall back to 1.0.
func test_terrain_mod_zero_falls_back_to_one() -> void:
	assert_almost_eq(_resolver.total_damage(36.0, 0.0, 1.0, 1.0), 36.0)


## AC: flanking mod computed incorrectly (Facing & Flank bug) → fall back
## to 1.0 and continue combat.
func test_invalid_flank_mod_falls_back_to_one() -> void:
	assert_almost_eq(_resolver.total_damage(36.0, 1.0, 0.5, 1.0), 36.0, 0.0001, "flank below 1.0 is invalid")
	assert_almost_eq(_resolver.total_damage(36.0, 1.0, 2.0, 1.0), 36.0, 0.0001, "flank above 1.0 + bonus is invalid")


## Determinism: identical inputs always produce identical damage (no RNG).
func test_damage_calculation_deterministic() -> void:
	var first := _resolver.total_damage(_resolver.base_damage_ranged(20, 80), 1.25, 1.3, 1.0)
	var second := _resolver.total_damage(_resolver.base_damage_ranged(20, 80), 1.25, 1.3, 1.0)
	assert_eq(first, second)
