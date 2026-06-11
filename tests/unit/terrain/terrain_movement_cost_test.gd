extends "res://tests/helpers/test_case.gd"
## Terrain System — movement costs with seasonal modifiers.
## Covers design/gdd/terrain-system.md acceptance criteria: per-type AP
## costs, Wet ×1.5 multiplier, river impassability, ford/bridge crossings,
## charred hexes, and mid-battle season recalculation.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _terrain: TerrainSystem


func setup() -> void:
	_terrain = Fixtures.terrain_system()


## AC: Road in Dry costs 1 AP per hex (5 hexes consume exactly 5 AP).
func test_road_dry_costs_one_ap() -> void:
	assert_eq(_terrain.movement_cost(TerrainSystem.TerrainType.ROAD, TerrainSystem.Season.DRY), 1)


## AC: Forest in Wet costs 3 AP (2 × 1.5).
func test_forest_wet_costs_three_ap() -> void:
	assert_eq(_terrain.movement_cost(TerrainSystem.TerrainType.FOREST, TerrainSystem.Season.DRY), 2)
	assert_eq(_terrain.movement_cost(TerrainSystem.TerrainType.FOREST, TerrainSystem.Season.WET), 3)


## Hill follows the same Wet multiplier (2 → 3 AP).
func test_hill_wet_costs_three_ap() -> void:
	assert_eq(_terrain.movement_cost(TerrainSystem.TerrainType.HILL, TerrainSystem.Season.DRY), 2)
	assert_eq(_terrain.movement_cost(TerrainSystem.TerrainType.HILL, TerrainSystem.Season.WET), 3)


## Open Field in Wet: ceil(1 × 1.5) = 2 AP.
func test_open_field_wet_costs_two_ap() -> void:
	assert_eq(_terrain.movement_cost(TerrainSystem.TerrainType.OPEN_FIELD, TerrainSystem.Season.WET), 2)


## GDD terrain table: Road and Village are "No change" across seasons.
func test_road_and_village_unaffected_by_wet_season() -> void:
	assert_eq(_terrain.movement_cost(TerrainSystem.TerrainType.ROAD, TerrainSystem.Season.WET), 1)
	assert_eq(_terrain.movement_cost(TerrainSystem.TerrainType.VILLAGE, TerrainSystem.Season.WET), 1)


## GDD river rules: Wet crossings cost 3 AP at fords, 2 AP at bridges.
func test_ford_and_bridge_wet_crossing_costs() -> void:
	assert_eq(_terrain.movement_cost(TerrainSystem.TerrainType.FORD, TerrainSystem.Season.DRY), 2)
	assert_eq(_terrain.movement_cost(TerrainSystem.TerrainType.FORD, TerrainSystem.Season.WET), 3)
	assert_eq(_terrain.movement_cost(TerrainSystem.TerrainType.BRIDGE, TerrainSystem.Season.DRY), 1)
	assert_eq(_terrain.movement_cost(TerrainSystem.TerrainType.BRIDGE, TerrainSystem.Season.WET), 2)


## AC: a river hex without ford/bridge cannot be entered — move rejected.
func test_river_impassable_in_every_season() -> void:
	assert_false(_terrain.is_passable(TerrainSystem.TerrainType.RIVER))
	for season: TerrainSystem.Season in TerrainSystem.Season.values():
		assert_eq(_terrain.movement_cost(TerrainSystem.TerrainType.RIVER, season), TerrainSystem.IMPASSABLE)


## GDD edge case: burned (charred) hexes block movement for the battle.
func test_charred_tile_becomes_impassable() -> void:
	var tile := TerrainTile.new(TerrainSystem.TerrainType.OPEN_FIELD)
	assert_eq(tile.movement_cost(_terrain, TerrainSystem.Season.DRY), 1)
	tile.set_charred()
	assert_eq(tile.movement_cost(_terrain, TerrainSystem.Season.DRY), TerrainSystem.IMPASSABLE)


## AC: Wet season beginning mid-battle → costs recalculate immediately
## (costs are computed on demand, so the same query reflects the new season).
func test_season_change_recalculates_costs_immediately() -> void:
	var tile := TerrainTile.new(TerrainSystem.TerrainType.FOREST)
	assert_eq(tile.movement_cost(_terrain, TerrainSystem.Season.DRY), 2)
	assert_eq(tile.movement_cost(_terrain, TerrainSystem.Season.WET), 3, "next move after season flip must cost Wet rate")
	assert_eq(tile.movement_cost(_terrain, TerrainSystem.Season.HARVEST), 2, "Harvest reverts to base cost")


## Output range invariant: every passable type in every season costs [1, 3] AP.
func test_movement_cost_output_range_one_to_three() -> void:
	for type: TerrainSystem.TerrainType in TerrainSystem.TerrainType.values():
		if not _terrain.is_passable(type):
			continue
		for season: TerrainSystem.Season in TerrainSystem.Season.values():
			assert_between(_terrain.movement_cost(type, season), 1, 3)
