class_name TerrainSystem
extends RefCounted
## Terrain property queries: movement cost, combat modifiers, flammability,
## vision — all season-aware.
##
## Implements design/gdd/terrain-system.md. Terrain is a read-only data
## layer: Hex Movement, Combat Resolution, Fire System, and Fog of War query
## it by terrain type; only the Campaign Layer changes the season.
## All numeric values come from assets/data/terrain.json (data-driven).

## The six GDD terrain types plus the two river-crossing variants.
enum TerrainType { ROAD, OPEN_FIELD, HILL, FOREST, VILLAGE, RIVER, FORD, BRIDGE }

## Seasonal states (GDD: Dry Act I–II, Wet Act II–III, Harvest Act III–IV).
enum Season { DRY, WET, HARVEST }

## Sentinel returned by movement-cost queries for impassable hexes.
const IMPASSABLE := -1

var _types: Dictionary = {}
var _season_multipliers: Dictionary = {}


## Builds the system from a parsed terrain.json Dictionary
## (see assets/data/terrain.json). Inject fixture data in tests.
static func from_config(config: Dictionary) -> TerrainSystem:
	var system := TerrainSystem.new()
	system._types = config.get("terrain_types", {})
	system._season_multipliers = config.get("season_multipliers", {})
	return system


## Convenience factory: loads assets/data/terrain.json from disk.
static func from_file(path: String = "res://assets/data/terrain.json") -> TerrainSystem:
	return from_config(ConfigLoader.load_json(path))


## True if squads can enter this terrain at all (River is impassable
## except at Ford/Bridge hexes, which are their own types).
func is_passable(type: TerrainType) -> bool:
	return bool(_props(type).get("passable", false))


## AP cost to enter one hex of [param type] during [param season].
## cost = ceil(base_cost × season_multiplier); the Wet ×1.5 multiplier only
## applies to types the GDD marks as seasonally affected (Road and Village
## are "No change"). Wet examples: Forest 2→3, Ford 2→3, Bridge 1→2.
## Returns IMPASSABLE (-1) for River or unknown types.
func movement_cost(type: TerrainType, season: Season) -> int:
	var props := _props(type)
	if props.is_empty() or not bool(props.get("passable", false)):
		return IMPASSABLE
	var base := float(props.get("base_cost", 1))
	var multiplier := 1.0
	if bool(props.get("wet_affected", false)):
		multiplier = float(_season_multipliers.get(_season_key(season), 1.0))
	return ceili(base * multiplier)


## Ranged damage modifier granted to an attacker firing FROM this terrain
## (Hill +0.25). Additive term, 0.0 when no effect.
func attacker_ranged_modifier(type: TerrainType) -> float:
	return float(_props(type).get("attacker_ranged_mod", 0.0))


## Ranged damage modifier applied when the TARGET stands on this terrain
## (Forest cover -0.25, Village buildings -0.15, Bridge/Ford cover -0.15).
## Additive term, 0.0 when no effect.
func defender_ranged_modifier(type: TerrainType) -> float:
	return float(_props(type).get("defender_ranged_mod", 0.0))


## Combined ranged terrain multiplier for Combat Resolution's terrain_mod:
## 1.0 + attacker-side bonus + defender-side cover.
## Output range [0.75, 1.25] per combat-resolution.md Formula 3.
func ranged_terrain_multiplier(attacker_type: TerrainType, defender_type: TerrainType) -> float:
	return 1.0 + attacker_ranged_modifier(attacker_type) + defender_ranged_modifier(defender_type)


## Melee terrain multiplier for an attacker ON this terrain (Hill -10%).
func melee_terrain_multiplier(attacker_type: TerrainType) -> float:
	return 1.0 + float(_props(attacker_type).get("attacker_melee_mod", 0.0))


## Defense multiplier for a defender occupying this terrain
## (Village/Bridge +15% → 1.15). When [param crossing_in_progress] is true
## the mid-crossing vulnerability applies (Ford -20% → 0.8).
func defense_multiplier(type: TerrainType, crossing_in_progress: bool = false) -> float:
	var props := _props(type)
	var mod := float(props.get("defense_mod", 0.0))
	if crossing_in_progress:
		mod += float(props.get("crossing_defense_mod", 0.0))
	return 1.0 + mod


## True if fire can ignite/spread on this terrain in this season
## (Open Field in Dry season only; Wet quenches fire).
func is_flammable(type: TerrainType, season: Season) -> bool:
	var seasons: Array = _props(type).get("flammable_seasons", [])
	return seasons.has(_season_key(season))


## Vision range modifier in hexes (Hill +1, everything else 0).
func vision_modifier(type: TerrainType) -> int:
	return int(_props(type).get("vision_mod", 0))


## True if this terrain blocks line-of-sight rays (Forest, Village —
## hex-movement.md F-6). Hill and River do NOT block.
func is_los_blocking(type: TerrainType) -> bool:
	return bool(_props(type).get("los_blocking", false))


## Forest ambush flanking bonus (+0.30 when attacking units entering the
## hex). 0.0 for non-forest terrain. Consumed by Facing & Flank (design #5).
func ambush_flank_bonus(type: TerrainType) -> float:
	return float(_props(type).get("ambush_flank_bonus", 0.0))


func _props(type: TerrainType) -> Dictionary:
	var key: String = (TerrainType.keys()[type] as String).to_lower() if type >= 0 and type < TerrainType.size() else ""
	if not _types.has(key):
		push_error("TerrainSystem: unknown terrain type %d" % type)
		return {}
	return _types[key]


func _season_key(season: Season) -> String:
	return (Season.keys()[season] as String).to_lower()
