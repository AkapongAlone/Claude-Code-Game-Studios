extends "res://tests/helpers/test_case.gd"
## Officer Passive Ability System — design/gdd/officer-passive-ability.md
## acceptance criteria: registration lifecycle, Juggernaut, Old Guard,
## Shadow Work, Vital Strike, Stratagem, Heirloom Blade (hidden).

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _registry: PassiveRegistry
var _officers: OfficerRegistry


func setup() -> void:
	_registry = Fixtures.passive_registry()
	_officers = Fixtures.officer_registry()


func _squad_for(officer_id: String, side: Squad.Side, position: Vector3i, unit_type: String = "swordsman") -> Squad:
	var officer := _officers.get_officer(officer_id) if officer_id != "" else null
	return Fixtures.battle_squad("s_%s" % (officer_id if officer_id != "" else "none"), side, position, officer, unit_type)


## AC 1: Kaster present → read_the_field + heirloom_blade registered.
func test_registration_at_battle_start() -> void:
	var kaster := _squad_for("kaster", Squad.Side.PLAYER, Vector3i.ZERO)
	_registry.register_battle([kaster])
	assert_true(_registry.has_passive("kaster", "read_the_field"))
	assert_true(_registry.has_passive("kaster", "heirloom_blade"))


## AC 2/3: deregistration removes passives; clear empties the registry.
func test_deregistration() -> void:
	var kaster := _squad_for("kaster", Squad.Side.PLAYER, Vector3i.ZERO)
	_registry.register_battle([kaster])
	_registry.deregister_officer("kaster")
	assert_false(_registry.has_passive("kaster", "heirloom_blade"))


## AC 15 (SECURITY): Heirloom Blade never appears in player-visible output.
func test_heirloom_blade_hidden_from_display() -> void:
	var kaster := _officers.get_officer("kaster")
	var names := _registry.display_passives(kaster)
	assert_true(names.has("Read the Field"))
	assert_false(names.has("Heirloom Blade"), "hidden passive must be filtered upstream")
	for name in names:
		assert_false(name.to_lower().contains("heirloom"), "no heirloom leakage in any label")


## AC 17–22: Juggernaut — all morale damage skipped; HP damage unaffected.
func test_juggernaut_blocks_all_morale_damage() -> void:
	var alexsen := _squad_for("alexsen", Squad.Side.PLAYER, Vector3i.ZERO)
	_registry.register_battle([alexsen])
	var morale := Fixtures.morale_system(_registry)
	alexsen.hp_lost_this_turn = alexsen.max_hp * 0.5
	alexsen.is_flanked_this_turn = true
	alexsen.officer_lost_this_turn = true
	morale.resolve_morale_phase([alexsen])
	assert_eq(alexsen.morale, 100, "morale never changes for Juggernaut")
	alexsen.take_damage(25.0)
	assert_almost_eq(alexsen.hp, alexsen.max_hp - 25.0 - 0.0, 0.01, "HP damage still applies")


## AC 39/41/42: Old Guard — adjacent friendly squads are flank-morale
## immune; distance 2 is not; Sander himself is not.
func test_old_guard_adjacency_rules() -> void:
	var sander := _squad_for("sander", Squad.Side.PLAYER, Vector3i.ZERO)
	var adjacent := Fixtures.battle_squad("adj", Squad.Side.PLAYER, Vector3i(1, -1, 0))
	var far := Fixtures.battle_squad("far", Squad.Side.PLAYER, Vector3i(2, -2, 0))
	var squads: Array = [sander, adjacent, far]
	_registry.register_battle(squads)
	assert_true(_registry.is_flank_morale_immune(adjacent, squads))
	assert_false(_registry.is_flank_morale_immune(far, squads), "radius is fixed at 1 hex")
	assert_false(_registry.is_flank_morale_immune(sander, squads), "not Sander's own squad")


## Old Guard end-to-end: adjacent flanked squad takes 0 flank morale damage.
func test_old_guard_suppresses_flank_trigger() -> void:
	var sander := _squad_for("sander", Squad.Side.PLAYER, Vector3i.ZERO)
	var adjacent := Fixtures.battle_squad("adj", Squad.Side.PLAYER, Vector3i(1, -1, 0))
	var squads: Array = [sander, adjacent]
	_registry.register_battle(squads)
	var morale := Fixtures.morale_system(_registry)
	adjacent.is_flanked_this_turn = true
	morale.resolve_morale_phase(squads)
	assert_eq(adjacent.morale, 70, "flank morale damage suppressed by Old Guard")


## AC 23–26: Shadow Work — melee from forest only.
func test_shadow_work_conditions() -> void:
	var thane_melee := _squad_for("thane", Squad.Side.PLAYER, Vector3i.ZERO, "swordsman")
	_registry.register_battle([thane_melee])
	assert_true(_registry.shadow_work_applies(thane_melee, true))
	assert_false(_registry.shadow_work_applies(thane_melee, false), "must be in forest")
	var thane_ranged := _squad_for("thane", Squad.Side.PLAYER, Vector3i.ZERO, "archer")
	_registry.register_battle([thane_ranged])
	assert_false(_registry.shadow_work_applies(thane_ranged, true), "ranged attacks never qualify")
	var other := _squad_for("kaster", Squad.Side.PLAYER, Vector3i.ZERO)
	_registry.register_battle([other])
	assert_false(_registry.shadow_work_applies(other, true), "only the Shadow Work officer")


## AC 27: Vital Strike queues −10 to enemy squads within 2 hexes of a kill.
func test_vital_strike_queues_morale_damage() -> void:
	var thane := _squad_for("thane", Squad.Side.PLAYER, Vector3i.ZERO)
	var killed := Fixtures.battle_squad("killed", Squad.Side.ENEMY, Vector3i(1, -1, 0))
	var near := Fixtures.battle_squad("near", Squad.Side.ENEMY, Vector3i(2, -2, 0))
	var far := Fixtures.battle_squad("far", Squad.Side.ENEMY, Vector3i(4, -4, 0))
	var friendly := Fixtures.battle_squad("friendly", Squad.Side.PLAYER, Vector3i(2, -1, -1))
	var squads: Array = [thane, killed, near, far, friendly]
	_registry.register_battle(squads)
	var affected := _registry.on_kill(thane, killed, squads)
	assert_eq(affected.size(), 1)
	assert_eq(near.pending_morale_damage, 10)
	assert_eq(far.pending_morale_damage, 0, "outside the 2-hex radius")
	assert_eq(friendly.pending_morale_damage, 0, "friendly squads unaffected")


## AC 29 equivalent: non-Vital-Strike officers queue nothing.
func test_vital_strike_requires_thane() -> void:
	var kaster := _squad_for("kaster", Squad.Side.PLAYER, Vector3i.ZERO)
	var killed := Fixtures.battle_squad("killed", Squad.Side.ENEMY, Vector3i(1, -1, 0))
	var near := Fixtures.battle_squad("near", Squad.Side.ENEMY, Vector3i(2, -2, 0))
	var squads: Array = [kaster, killed, near]
	_registry.register_battle(squads)
	_registry.on_kill(kaster, killed, squads)
	assert_eq(near.pending_morale_damage, 0)


## AC 37–38: Stratagem grants +1 while Bon is active; 0 once BROKEN.
func test_stratagem_vision_bonus_lifecycle() -> void:
	var bon := _squad_for("bon_shi_hai", Squad.Side.PLAYER, Vector3i.ZERO)
	var squads: Array = [bon]
	_registry.register_battle(squads)
	assert_eq(_registry.vision_bonus_for_side(Squad.Side.PLAYER, squads), 1)
	assert_eq(_registry.vision_bonus_for_side(Squad.Side.ENEMY, squads), 0)
	bon.set_morale(0)
	assert_eq(_registry.vision_bonus_for_side(Squad.Side.PLAYER, squads), 0, "BROKEN Bon grants nothing")


## AC 12–13: blade ceiling — Kaster swordsman 91, musketeer 103.
func test_blade_damage_ceiling_values() -> void:
	var melee := _squad_for("kaster", Squad.Side.PLAYER, Vector3i.ZERO, "swordsman")
	var ranged := _squad_for("kaster", Squad.Side.PLAYER, Vector3i.ZERO, "musketeer")
	_registry.register_battle([melee])
	assert_almost_eq(_registry.blade_damage_ceiling(melee), 91.0)
	assert_almost_eq(_registry.blade_damage_ceiling(ranged), 103.0)


## AC 16: proc rate 0.0 never fires.
func test_blade_proc_rate_zero_never_fires() -> void:
	var config := Fixtures.passive_config()
	config["blade_proc_rate"] = 0.0
	var registry := PassiveRegistry.from_config(config, Fixtures.combat_config())
	var kaster := _squad_for("kaster", Squad.Side.PLAYER, Vector3i.ZERO)
	registry.register_battle([kaster])
	var rng := Fixtures.seeded_rng()
	for i in 100:
		assert_almost_eq(registry.roll_blade_proc(kaster, rng), -1.0)
