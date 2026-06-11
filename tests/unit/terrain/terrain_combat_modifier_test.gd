extends "res://tests/helpers/test_case.gd"
## Terrain System — combat modifiers, flammability, vision.
## Covers design/gdd/terrain-system.md acceptance criteria: hill +25%
## ranged, forest cover -25%, village defense +15%, ford crossing -20%,
## Dry-only fire, hill vision.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _terrain: TerrainSystem


func setup() -> void:
	_terrain = Fixtures.terrain_system()


## AC: ranged attacker on a Hill → damage × 1.25.
func test_hill_attacker_ranged_multiplier_125() -> void:
	assert_almost_eq(_terrain.attacker_ranged_modifier(TerrainSystem.TerrainType.HILL), 0.25)
	assert_almost_eq(
		_terrain.ranged_terrain_multiplier(TerrainSystem.TerrainType.HILL, TerrainSystem.TerrainType.OPEN_FIELD),
		1.25
	)


## Forest cover: ranged attacks against units in Forest → damage × 0.75.
func test_forest_defender_cover_multiplier_075() -> void:
	assert_almost_eq(
		_terrain.ranged_terrain_multiplier(TerrainSystem.TerrainType.OPEN_FIELD, TerrainSystem.TerrainType.FOREST),
		0.75
	)


## Village buildings: ranged attacks against village hexes → damage × 0.85.
func test_village_defender_ranged_multiplier_085() -> void:
	assert_almost_eq(
		_terrain.ranged_terrain_multiplier(TerrainSystem.TerrainType.OPEN_FIELD, TerrainSystem.TerrainType.VILLAGE),
		0.85
	)


## Attacker-side and defender-side modifiers stack additively:
## Hill attacker (+0.25) vs Village target (-0.15) → 1.10.
func test_hill_versus_village_stacks_additively() -> void:
	assert_almost_eq(
		_terrain.ranged_terrain_multiplier(TerrainSystem.TerrainType.HILL, TerrainSystem.TerrainType.VILLAGE),
		1.10
	)


## Hill melee penalty: melee attacker on a Hill → damage × 0.9.
func test_hill_melee_multiplier_090() -> void:
	assert_almost_eq(_terrain.melee_terrain_multiplier(TerrainSystem.TerrainType.HILL), 0.90)
	assert_almost_eq(_terrain.melee_terrain_multiplier(TerrainSystem.TerrainType.OPEN_FIELD), 1.0)


## AC: defender in Village with base defense 50 → effective defense 57.5.
func test_village_defense_multiplier_115() -> void:
	var multiplier := _terrain.defense_multiplier(TerrainSystem.TerrainType.VILLAGE)
	assert_almost_eq(multiplier, 1.15)
	assert_almost_eq(50.0 * multiplier, 57.5)


## AC: squad mid-crossing a Ford → defense × 0.8 (-20% vulnerability).
func test_ford_mid_crossing_defense_multiplier_080() -> void:
	assert_almost_eq(_terrain.defense_multiplier(TerrainSystem.TerrainType.FORD, true), 0.80)
	assert_almost_eq(_terrain.defense_multiplier(TerrainSystem.TerrainType.FORD, false), 1.0, 0.0001, "no penalty when not crossing")


## TerrainTile carries the crossing state into the defense query.
func test_tile_crossing_state_applies_penalty() -> void:
	var tile := TerrainTile.new(TerrainSystem.TerrainType.FORD)
	assert_almost_eq(tile.defense_multiplier(_terrain), 1.0)
	tile.crossing_in_progress = true
	assert_almost_eq(tile.defense_multiplier(_terrain), 0.80)


## AC: Open Field is flammable in Dry only — Wet quenches fire; Harvest no.
func test_open_field_flammable_in_dry_season_only() -> void:
	assert_true(_terrain.is_flammable(TerrainSystem.TerrainType.OPEN_FIELD, TerrainSystem.Season.DRY))
	assert_false(_terrain.is_flammable(TerrainSystem.TerrainType.OPEN_FIELD, TerrainSystem.Season.WET))
	assert_false(_terrain.is_flammable(TerrainSystem.TerrainType.OPEN_FIELD, TerrainSystem.Season.HARVEST))


## GDD: fire only spreads on fields — no other type is ever flammable.
func test_non_field_terrain_never_flammable() -> void:
	for type: TerrainSystem.TerrainType in TerrainSystem.TerrainType.values():
		if type == TerrainSystem.TerrainType.OPEN_FIELD:
			continue
		for season: TerrainSystem.Season in TerrainSystem.Season.values():
			assert_false(_terrain.is_flammable(type, season), "%s must not be flammable" % TerrainSystem.TerrainType.keys()[type])


## Hill raises vision range by 1 hex; flat terrain adds nothing.
func test_hill_vision_modifier_plus_one() -> void:
	assert_eq(_terrain.vision_modifier(TerrainSystem.TerrainType.HILL), 1)
	assert_eq(_terrain.vision_modifier(TerrainSystem.TerrainType.OPEN_FIELD), 0)
	assert_eq(_terrain.vision_modifier(TerrainSystem.TerrainType.FOREST), 0)


## Forest ambush grants the +30% flanking bonus (consumed by Facing & Flank).
func test_forest_ambush_flank_bonus_030() -> void:
	assert_almost_eq(_terrain.ambush_flank_bonus(TerrainSystem.TerrainType.FOREST), 0.30)
	assert_almost_eq(_terrain.ambush_flank_bonus(TerrainSystem.TerrainType.OPEN_FIELD), 0.0)
