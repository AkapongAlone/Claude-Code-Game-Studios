class_name Squad
extends RefCounted
## A combat squad: HP pool, unit type, commanding officer, and the tile it
## occupies. The minimal state Combat Resolution needs to resolve an attack.
##
## Supports design/gdd/combat-resolution.md. Unit base damage and HP come
## from assets/data/combat.json (data-driven). Morale here is a placeholder
## enum until the Morale System GDD (design order #4) specifies real states.

## How this squad attacks. Ranged requires line of sight and cannot strike
## adjacent hexes; melee strikes adjacent hexes only (range/LoS validation
## is owned by Hex Movement / Facing & Flank — not yet designed).
enum AttackKind { RANGED, MELEE }

## Placeholder morale states consumed by Combat Resolution:
## NORMAL → damage ×1.0; BROKEN → attacker deals 50%, defender loses defense.
enum MoraleState { NORMAL, BROKEN }

## Unique squad identifier.
var id: String = ""
## Unit type key into combat.json (e.g. "archer", "swordsman").
var unit_type_id: String = ""
## Ranged or melee resolution path.
var attack_kind: AttackKind = AttackKind.MELEE
## Squad-type base damage before officer/terrain/position modifiers.
var unit_base: int = 0
## Maximum HP pool.
var max_hp: float = 0.0
## Current HP. Clamped to [0, max_hp]; 0 means the squad is killed.
var hp: float = 0.0
## Commanding officer, or null for an officer-less squad (defense = 0).
var officer: Officer = null
## Current morale state (owned by the Morale System once designed).
var morale_state: MoraleState = MoraleState.NORMAL
## The hex tile this squad occupies (terrain type + charred/crossing state).
var tile: TerrainTile = null


## Builds a squad of [param p_unit_type_id] from a combat.json config.
## Returns null (and logs an error) for unknown unit types.
static func create(p_id: String, p_unit_type_id: String, combat_config: Dictionary, p_officer: Officer = null, p_tile: TerrainTile = null) -> Squad:
	var unit_types: Dictionary = combat_config.get("unit_types", {})
	if not unit_types.has(p_unit_type_id):
		push_error("Squad: unknown unit type '%s'" % p_unit_type_id)
		return null
	var unit: Dictionary = unit_types[p_unit_type_id]
	var squad := Squad.new()
	squad.id = p_id
	squad.unit_type_id = p_unit_type_id
	squad.attack_kind = AttackKind.RANGED if String(unit.get("attack", "melee")) == "ranged" else AttackKind.MELEE
	squad.unit_base = int(unit.get("unit_base", 0))
	squad.max_hp = float(unit.get("max_hp", 0))
	squad.hp = squad.max_hp
	squad.officer = p_officer
	squad.tile = p_tile
	return squad


## Applies damage to the HP pool. HP below 0 is clamped to 0 (GDD edge
## case: no negative HP; treat as killed).
func take_damage(amount: float) -> void:
	hp = clampf(hp - amount, 0.0, max_hp)


## True when HP has reached 0 — the squad is removed from the map.
func is_dead() -> bool:
	return hp <= 0.0
