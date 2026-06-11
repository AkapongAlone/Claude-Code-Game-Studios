class_name CombatResolver
extends RefCounted
## Stateless damage calculation for squad-vs-squad tactical combat.
##
## Implements design/gdd/combat-resolution.md. Deterministic — no RNG
## anywhere in the pipeline: outcomes follow purely from officer stats,
## terrain, positioning, and morale. All tuning values come from
## assets/data/combat.json (data-driven). TerrainSystem is injected so the
## resolver never touches the filesystem (testable in isolation).
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
var _broken_morale_damage_mod: float = 0.5
var _defense_cap: float = 0.90
var _ldr_defense_scale: float = 0.5
var _damage_cap: float = 90.0
var _terrain: TerrainSystem = null


## Builds a resolver from a parsed combat.json Dictionary with an injected
## TerrainSystem. Inject fixture data in tests.
static func from_config(config: Dictionary, terrain: TerrainSystem) -> CombatResolver:
	var resolver := CombatResolver.new()
	resolver._ranged_war_divisor = float(config.get("ranged_war_divisor", 100.0))
	resolver._melee_war_divisor = float(config.get("melee_war_divisor", 200.0))
	resolver._flank_bonus = float(config.get("flank_bonus", 0.30))
	resolver._broken_morale_damage_mod = float(config.get("broken_morale_damage_mod", 0.5))
	resolver._defense_cap = float(config.get("defense_cap", 0.90))
	resolver._ldr_defense_scale = float(config.get("ldr_defense_scale", 0.5))
	resolver._damage_cap = float(config.get("damage_cap", 90.0))
	resolver._terrain = terrain
	return resolver


## Formula 1: ranged base damage = unit_base × (1 + WAR / 100).
## Example: archer 20, WAR 80 → 20 × 1.8 = 36.
func base_damage_ranged(unit_base: int, war: int) -> float:
	return unit_base * (1.0 + war / _ranged_war_divisor)


## Formula 2: melee base damage = unit_base × (1 + WAR / 200).
## Example: swordsman 40, WAR 80 → 40 × 1.4 = 56.
func base_damage_melee(unit_base: int, war: int) -> float:
	return unit_base * (1.0 + war / _melee_war_divisor)


## Formula 3: damage_dealt = base × terrain_mod × flank_mod × morale_mod,
## capped at damage_cap (90). Safety fallbacks per GDD edge cases:
## terrain_mod ≤ 0 (no terrain assigned) → 1.0; flank_mod outside
## [1.0, 1.0 + flank_bonus] (Facing & Flank bug) → 1.0.
func total_damage(base_damage: float, terrain_mod: float, flank_mod: float, morale_mod: float) -> float:
	if terrain_mod <= 0.0:
		terrain_mod = 1.0
	if flank_mod < 1.0 or flank_mod > 1.0 + _flank_bonus:
		flank_mod = 1.0
	return minf(base_damage * terrain_mod * flank_mod * morale_mod, _damage_cap)


## Defense value = LDR × 0.5 × terrain defense multiplier.
## Officer-less squads pass ldr = 0 → defense 0.
## Example: LDR 80 in village → 80 × 0.5 × 1.15 = 46.
func defense_value(ldr: int, terrain_defense_multiplier: float) -> float:
	return ldr * _ldr_defense_scale * terrain_defense_multiplier


## Formula 4: effective_damage = damage × (1 - min(defense / 100, 0.9)).
## Defense reduction is hard-capped at 90%.
## Example: 100 damage vs defense 46 → 100 × 0.54 = 54.
func effective_damage(damage_dealt: float, defense: float) -> float:
	return damage_dealt * (1.0 - minf(defense / 100.0, _defense_cap))


## Resolves a full attack and applies damage to the defender's HP pool.
##
## Validity (range / line of sight) is owned by Hex Movement and
## Facing & Flank (design #5–6, not yet built); callers pass the resolved
## [param is_flanking] state. Edge cases handled here per GDD:
## self-attack rejected; missing officer → WAR/LDR contribution 0; missing
## tile → terrain_mod 1.0; broken attacker deals 50%; broken defender
## takes 100% (defense 0); HP clamped at 0.
func resolve_attack(attacker: Squad, defender: Squad, is_flanking: bool = false) -> AttackResult:
	var result := AttackResult.new()
	if attacker == null or defender == null:
		push_error("CombatResolver: resolve_attack called with null squad — rejected")
		return result
	if attacker == defender:
		push_error("CombatResolver: squad '%s' attempted to attack itself — rejected" % attacker.id)
		return result
	result.valid = true

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
	var morale_mod := _broken_morale_damage_mod if attacker.morale_state == Squad.MoraleState.BROKEN else 1.0
	result.damage_dealt = total_damage(result.base_damage, terrain_mod, flank_mod, morale_mod)

	var defense := 0.0
	if defender.morale_state != Squad.MoraleState.BROKEN and defender.officer != null:
		var defense_multiplier := 1.0
		if _terrain != null and defender.tile != null:
			defense_multiplier = defender.tile.defense_multiplier(_terrain)
		defense = defense_value(defender.officer.ldr(), defense_multiplier)
	result.effective_damage = effective_damage(result.damage_dealt, defense)

	defender.take_damage(result.effective_damage)
	result.defender_hp_after = defender.hp
	result.defender_killed = defender.is_dead()
	return result
