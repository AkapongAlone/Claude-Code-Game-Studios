class_name CombatResolver
extends RefCounted
## Stateless damage calculation for squad-vs-squad tactical combat.
##
## Implements design/gdd/combat-resolution.md (plus the SHAKEN morale state
## from morale-system.md and the ford-crossing defense penalty from
## hex-movement.md). Deterministic — no RNG anywhere in the pipeline.
## All tuning values come from assets/data/combat.json (data-driven).
## Range / line-of-sight / visibility validation is owned by the battle
## controller; the resolver only calculates.
##
## Pipeline (Formula order per GDD):
##   1. base damage from attacker WAR        → base_damage_ranged/melee()
##   2. × terrain × flank × morale, capped   → total_damage()
##   3. defender defense from LDR + terrain  → defense_value()
##   4. damage after reduction (90% cap)     → effective_damage()

## Outcome of one resolved attack, consumed by Tactical HUD (damage
## numbers), Morale System (casualties), and Victory Conditions.
class AttackResult:
	extends RefCounted
	## False when the attack was rejected (e.g. self-attack).
	var valid: bool = false
	## True when this attack resolved as a flank attack.
	var was_flank: bool = false
	## WAR-derived damage before modifiers (Formula 1/2).
	var base_damage: float = 0.0
	## Damage after terrain/flank/morale modifiers and cap (Formula 3).
	var damage_dealt: float = 0.0
	## Damage actually applied after defender's defense (Formula 4).
	var effective_damage: float = 0.0
	## Defender HP remaining after the hit (clamped at 0).
	var defender_hp_after: float = 0.0
	## True when the hit reduced defender HP to 0 (squad removed).
	var defender_killed: bool = false

var _ranged_war_divisor: float = 100.0
var _melee_war_divisor: float = 200.0
var _flank_bonus: float = 0.30
var _morale_mods: Dictionary = { "steady": 1.0, "shaken": 0.75, "broken": 0.5 }
var _defense_cap: float = 0.90
var _ldr_defense_scale: float = 0.5
var _damage_cap: float = 90.0
var _ford_crossing_defense_mod: float = -0.20
var _terrain: TerrainSystem = null


## Builds a resolver from a parsed combat.json Dictionary with an injected
## TerrainSystem. Inject fixture data in tests.
static func from_config(config: Dictionary, terrain: TerrainSystem) -> CombatResolver:
	var resolver := CombatResolver.new()
	resolver._ranged_war_divisor = float(config.get("ranged_war_divisor", 100.0))
	resolver._melee_war_divisor = float(config.get("melee_war_divisor", 200.0))
	resolver._flank_bonus = float(config.get("flank_bonus", 0.30))
	resolver._morale_mods = config.get("morale_damage_mods", resolver._morale_mods)
	resolver._defense_cap = float(config.get("defense_cap", 0.90))
	resolver._ldr_defense_scale = float(config.get("ldr_defense_scale", 0.5))
	resolver._damage_cap = float(config.get("damage_cap", 90.0))
	resolver._ford_crossing_defense_mod = float(config.get("ford_crossing_defense_mod", -0.20))
	resolver._terrain = terrain
	return resolver


## Formula 1: ranged base damage = unit_base × (1 + WAR / 100).
func base_damage_ranged(unit_base: int, war: int) -> float:
	return unit_base * (1.0 + war / _ranged_war_divisor)


## Formula 2: melee base damage = unit_base × (1 + WAR / 200).
func base_damage_melee(unit_base: int, war: int) -> float:
	return unit_base * (1.0 + war / _melee_war_divisor)


## Formula 3: damage_dealt = base × terrain_mod × flank_mod × morale_mod,
## capped at damage_cap (90). Safety fallbacks per GDD edge cases:
## terrain_mod ≤ 0 → 1.0; flank_mod outside [1.0, 1.0 + flank_bonus] → 1.0.
func total_damage(base_damage: float, terrain_mod: float, flank_mod: float, morale_mod: float) -> float:
	if terrain_mod <= 0.0:
		terrain_mod = 1.0
	if flank_mod < 1.0 or flank_mod > 1.0 + _flank_bonus:
		flank_mod = 1.0
	return minf(base_damage * terrain_mod * flank_mod * morale_mod, _damage_cap)


## Attacker damage multiplier from morale state:
## STEADY 1.0 / SHAKEN 0.75 / BROKEN 0.5.
func morale_mod_for(state: Squad.MoraleState) -> float:
	match state:
		Squad.MoraleState.SHAKEN:
			return float(_morale_mods.get("shaken", 0.75))
		Squad.MoraleState.BROKEN:
			return float(_morale_mods.get("broken", 0.5))
		_:
			return float(_morale_mods.get("steady", 1.0))


## Defense value = LDR × 0.5 × terrain defense multiplier.
func defense_value(ldr: int, terrain_defense_multiplier: float) -> float:
	return ldr * _ldr_defense_scale * terrain_defense_multiplier


## Formula 4: effective_damage = damage × (1 - min(defense / 100, 0.9)).
func effective_damage(damage_dealt: float, defense: float) -> float:
	return damage_dealt * (1.0 - minf(defense / 100.0, _defense_cap))


## Resolves a full attack and applies damage to the defender's HP pool.
##
## [param is_flanking] is supplied by Facing & Flank (or passive overrides).
## [param damage_override] > 0 replaces damage_dealt with the given value
## (Heirloom Blade proc — uses formula maximums, bypasses the cap).
## Edge cases per GDD: self-attack rejected; missing officer → WAR/LDR 0;
## missing tile → terrain_mod 1.0; broken attacker deals 50%; SHAKEN 75%;
## broken defender takes 100% (defense 0); ford crossing −20% defense;
## HP clamped at 0.
func resolve_attack(attacker: Squad, defender: Squad, is_flanking: bool = false, damage_override: float = -1.0) -> AttackResult:
	var result := AttackResult.new()
	if attacker == null or defender == null:
		push_error("CombatResolver: resolve_attack called with null squad — rejected")
		return result
	if attacker == defender:
		push_error("CombatResolver: squad '%s' attempted to attack itself — rejected" % attacker.id)
		return result
	result.valid = true
	result.was_flank = is_flanking

	var war: int = attacker.officer.war() if attacker.officer != null else 0
	if attacker.attack_kind == Squad.AttackKind.RANGED:
		result.base_damage = base_damage_ranged(attacker.unit_base, war)
	else:
		result.base_damage = base_damage_melee(attacker.unit_base, war)

	var terrain_mod := 1.0
	if _terrain != null and attacker.tile != null and defender.tile != null:
		if attacker.attack_kind == Squad.AttackKind.RANGED:
			terrain_mod = _terrain.ranged_terrain_multiplier(attacker.tile.type, defender.tile.type)
		else:
			terrain_mod = _terrain.melee_terrain_multiplier(attacker.tile.type)

	var flank_mod := 1.0 + _flank_bonus if is_flanking else 1.0
	var morale_mod := morale_mod_for(attacker.morale_state)
	if damage_override > 0.0:
		result.damage_dealt = damage_override
	else:
		result.damage_dealt = total_damage(result.base_damage, terrain_mod, flank_mod, morale_mod)

	var defense := 0.0
	if defender.morale_state != Squad.MoraleState.BROKEN and defender.officer != null:
		var defense_multiplier := 1.0
		if _terrain != null and defender.tile != null:
			defense_multiplier = defender.tile.defense_multiplier(_terrain)
		if defender.crossed_ford_this_turn:
			defense_multiplier += _ford_crossing_defense_mod
		defense = defense_value(defender.officer.ldr(), defense_multiplier)
	result.effective_damage = effective_damage(result.damage_dealt, defense)

	defender.take_damage(result.effective_damage)
	result.defender_hp_after = defender.hp
	result.defender_killed = defender.is_dead()
	if is_flanking:
		defender.is_flanked_this_turn = true
	return result
