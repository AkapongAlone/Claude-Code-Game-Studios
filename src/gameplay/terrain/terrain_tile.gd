class_name TerrainTile
extends RefCounted
## Per-hex tile state: terrain type plus battle-scoped flags.
##
## Implements the stateful edge cases of design/gdd/terrain-system.md:
## charred hexes (burned by fire) block movement for the rest of the battle,
## and a squad mid-crossing a Ford suffers the -20% defense vulnerability.
## Terrain *properties* stay in TerrainSystem; the tile only carries state.

## The terrain type occupying this hex.
var type: TerrainSystem.TerrainType = TerrainSystem.TerrainType.OPEN_FIELD
## True once fire has burned this hex. Charred hexes block movement for the
## battle's duration; charred Forest retains its cover bonus (GDD edge case).
var charred: bool = false
## True while a squad on this Ford hex is mid-crossing (1-turn minimum).
var crossing_in_progress: bool = false


func _init(p_type: TerrainSystem.TerrainType = TerrainSystem.TerrainType.OPEN_FIELD) -> void:
	type = p_type


## AP cost to enter this hex in [param season] via [param terrain].
## Charred hexes are IMPASSABLE regardless of underlying type.
func movement_cost(terrain: TerrainSystem, season: TerrainSystem.Season) -> int:
	if charred:
		return TerrainSystem.IMPASSABLE
	return terrain.movement_cost(type, season)


## Defense multiplier for a defender on this hex (includes the Ford
## mid-crossing penalty when crossing_in_progress is set).
func defense_multiplier(terrain: TerrainSystem) -> float:
	return terrain.defense_multiplier(type, crossing_in_progress)


## Marks this hex as burned. Fire damage to occupants is applied once by
## the Fire System (Alpha tier); repeated burns are idempotent.
func set_charred() -> void:
	charred = true
