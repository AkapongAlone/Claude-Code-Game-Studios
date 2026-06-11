extends "res://tests/helpers/test_case.gd"
## Combat Resolution — defense (formula 4) and the full resolve_attack
## pipeline. Covers design/gdd/combat-resolution.md acceptance criteria:
## LDR-based defense with terrain bonus, 90% reduction cap, squad death at
## 0 HP, self-attack rejection, broken-defender behavior.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _resolver: CombatResolver


func setup() -> void:
	_resolver = Fixtures.combat_resolver()


## AC: defender LDR 80 in Village (+15%) vs 100 damage →
## defense = 40 × 1.15 = 46; damage taken = 100 × (1 - 0.46) = 54.
func test_ldr80_in_village_takes_54_of_100() -> void:
	var defense := _resolver.defense_value(80, 1.15)
	assert_almost_eq(defense, 46.0)
	assert_almost_eq(_resolver.effective_damage(100.0, defense), 54.0)


## Defense reduction is hard-capped at 90% no matter how high defense gets.
func test_defense_reduction_capped_at_90_percent() -> void:
	assert_almost_eq(_resolver.effective_damage(100.0, 200.0), 10.0)


## Officer-less squads have defense 0 → take full damage.
func test_officerless_defender_takes_full_damage() -> void:
	var attacker := Fixtures.make_squad("att", "archer", Fixtures.make_officer("a1", 80, 50, 50, 50, 50), TerrainSystem.TerrainType.OPEN_FIELD)
	var defender := Fixtures.make_squad("def", "swordsman", null, TerrainSystem.TerrainType.OPEN_FIELD)
	var result := _resolver.resolve_attack(attacker, defender)
	assert_true(result.valid)
	assert_almost_eq(result.damage_dealt, 36.0)
	assert_almost_eq(result.effective_damage, 36.0, 0.0001, "no officer → defense 0 → full damage")


## Full pipeline: archer (WAR 80) on Hill vs swordsman (LDR 80) in Village.
## terrain_mod = 1 + 0.25 - 0.15 = 1.10 → damage_dealt = 39.6;
## defense = 46 → effective = 39.6 × 0.54 = 21.384; HP 120 → 98.616.
func test_resolve_attack_full_pipeline() -> void:
	var attacker := Fixtures.make_squad("att", "archer", Fixtures.make_officer("a1", 80, 50, 50, 50, 50), TerrainSystem.TerrainType.HILL)
	var defender := Fixtures.make_squad("def", "swordsman", Fixtures.make_officer("d1", 50, 80, 50, 50, 50), TerrainSystem.TerrainType.VILLAGE)
	var result := _resolver.resolve_attack(attacker, defender)
	assert_true(result.valid)
	assert_almost_eq(result.base_damage, 36.0)
	assert_almost_eq(result.damage_dealt, 39.6)
	assert_almost_eq(result.effective_damage, 21.384)
	assert_almost_eq(result.defender_hp_after, 98.616)
	assert_false(result.defender_killed)


## AC: HP reaches 0 → squad killed; HP below 0 clamps to 0.
func test_hp_reaches_zero_squad_killed() -> void:
	var attacker := Fixtures.make_squad("att", "swordsman", Fixtures.make_officer("a1", 98, 50, 50, 50, 50), TerrainSystem.TerrainType.OPEN_FIELD)
	var defender := Fixtures.make_squad("def", "archer", null, TerrainSystem.TerrainType.OPEN_FIELD)
	defender.hp = 30.0
	var result := _resolver.resolve_attack(attacker, defender)
	assert_almost_eq(result.damage_dealt, 59.6, 0.0001, "40 × (1 + 98/200)")
	assert_true(result.defender_killed)
	assert_almost_eq(defender.hp, 0.0, 0.0001, "HP clamps at 0, never negative")


## GDD edge case: self-attack is invalid — rejected, no damage applied.
## (The push_error output below is EXPECTED noise from this test.)
func test_self_attack_rejected() -> void:
	var squad := Fixtures.make_squad("solo", "archer", Fixtures.make_officer("a1", 80, 50, 50, 50, 50), TerrainSystem.TerrainType.OPEN_FIELD)
	var result := _resolver.resolve_attack(squad, squad)
	assert_false(result.valid)
	assert_almost_eq(squad.hp, squad.max_hp, 0.0001, "no damage on rejected attack")


## GDD edge case: broken defender takes 100% damage (defense cannot apply).
func test_broken_defender_takes_full_damage() -> void:
	var attacker := Fixtures.make_squad("att", "archer", Fixtures.make_officer("a1", 80, 50, 50, 50, 50), TerrainSystem.TerrainType.OPEN_FIELD)
	var defender := Fixtures.make_squad("def", "swordsman", Fixtures.make_officer("d1", 50, 80, 50, 50, 50), TerrainSystem.TerrainType.VILLAGE)
	defender.morale_state = Squad.MoraleState.BROKEN
	var result := _resolver.resolve_attack(attacker, defender)
	assert_almost_eq(result.effective_damage, result.damage_dealt, 0.0001, "broken defender gets no defense reduction")


## Broken ATTACKER through the full pipeline: damage halved before defense.
func test_broken_attacker_pipeline_halves_damage() -> void:
	var attacker := Fixtures.make_squad("att", "archer", Fixtures.make_officer("a1", 80, 50, 50, 50, 50), TerrainSystem.TerrainType.OPEN_FIELD)
	var defender := Fixtures.make_squad("def", "swordsman", null, TerrainSystem.TerrainType.OPEN_FIELD)
	attacker.morale_state = Squad.MoraleState.BROKEN
	var result := _resolver.resolve_attack(attacker, defender)
	assert_almost_eq(result.damage_dealt, 18.0, 0.0001, "36 × 0.5 morale mod")


## Squad factory rejects unknown unit types with null.
## (The push_error output below is EXPECTED noise from this test.)
func test_unknown_unit_type_returns_null() -> void:
	assert_null(Squad.create("bad", "catapult", Fixtures.combat_config()))
