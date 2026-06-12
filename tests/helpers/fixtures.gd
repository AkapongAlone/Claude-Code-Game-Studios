extends RefCounted
## Factory functions for test fixtures.
##
## Fixtures load the project's real data files (assets/data/*.json) — the
## shipped balance values ARE the values under test, since the GDD
## acceptance criteria reference them directly. Systems still receive the
## parsed Dictionary via dependency injection, so a test can substitute a
## custom config at any time.

const ConfigLoaderScript := preload("res://src/core/config_loader.gd")
const OfficerScript := preload("res://src/gameplay/officers/officer.gd")
const OfficerRegistryScript := preload("res://src/gameplay/officers/officer_registry.gd")
const TerrainSystemScript := preload("res://src/gameplay/terrain/terrain_system.gd")
const TerrainTileScript := preload("res://src/gameplay/terrain/terrain_tile.gd")
const SquadScript := preload("res://src/gameplay/combat/squad.gd")
const CombatResolverScript := preload("res://src/gameplay/combat/combat_resolver.gd")
const BattleGridScript := preload("res://src/gameplay/battle/battle_grid.gd")
const MoraleSystemScript := preload("res://src/gameplay/morale/morale_system.gd")
const PassiveRegistryScript := preload("res://src/gameplay/officers/passive_registry.gd")
const FogOfWarScript := preload("res://src/gameplay/fog/fog_of_war.gd")
const DuelEngineScript := preload("res://src/gameplay/duel/duel_engine.gd")
const VictoryCheckerScript := preload("res://src/gameplay/victory/victory_checker.gd")

## Fixed seed: tests must be deterministic across runs.
const DEFAULT_SEED := 13371337


static func officers_config() -> Dictionary:
	return ConfigLoaderScript.load_json("res://assets/data/officers.json")


static func terrain_config() -> Dictionary:
	return ConfigLoaderScript.load_json("res://assets/data/terrain.json")


static func combat_config() -> Dictionary:
	return ConfigLoaderScript.load_json("res://assets/data/combat.json")


static func morale_config() -> Dictionary:
	return ConfigLoaderScript.load_json("res://assets/data/morale.json")


static func movement_config() -> Dictionary:
	return ConfigLoaderScript.load_json("res://assets/data/movement.json")


static func vision_config() -> Dictionary:
	return ConfigLoaderScript.load_json("res://assets/data/vision.json")


static func duel_config() -> Dictionary:
	return ConfigLoaderScript.load_json("res://assets/data/duel_config.json")


static func passive_config() -> Dictionary:
	return ConfigLoaderScript.load_json("res://assets/data/passive_config.json")


static func battle_definition() -> Dictionary:
	return ConfigLoaderScript.load_json("res://assets/data/battles/open_field_demo.json")


static func officer_registry() -> OfficerRegistry:
	return OfficerRegistryScript.from_config(officers_config())


static func terrain_system() -> TerrainSystem:
	return TerrainSystemScript.from_config(terrain_config())


static func combat_resolver(terrain: TerrainSystem = null) -> CombatResolver:
	if terrain == null:
		terrain = terrain_system()
	return CombatResolverScript.from_config(combat_config(), terrain)


static func morale_system(passives: PassiveRegistry = null) -> MoraleSystem:
	var system: MoraleSystem = MoraleSystemScript.from_config(morale_config())
	system.passives = passives
	return system


static func passive_registry() -> PassiveRegistry:
	return PassiveRegistryScript.from_config(passive_config(), combat_config())


static func duel_engine(config_override: Dictionary = {}) -> DuelEngine:
	var config := duel_config()
	for key: String in config_override:
		config[key] = config_override[key]
	return DuelEngineScript.from_config(config)


static func grid_from_rows(rows: Array, season: TerrainSystem.Season = TerrainSystem.Season.DRY) -> BattleGrid:
	return BattleGridScript.from_map_rows(rows, terrain_system(), season)


static func fog_of_war(grid: BattleGrid, passives: PassiveRegistry = null) -> FogOfWar:
	return FogOfWarScript.from_config(vision_config(), grid, passives)


## Seeded RNG so randomized paths are reproducible run-to-run.
static func seeded_rng(rng_seed: int = DEFAULT_SEED) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	return rng


## Builds a standalone officer with explicit stats (boundary-value tests).
static func make_officer(id: String, war: int, ldr: int, intel: int, pol: int, chr: int, named: bool = true) -> Officer:
	return OfficerScript.create(
		id, id.capitalize(),
		{ "war": war, "ldr": ldr, "int": intel, "pol": pol, "chr": chr },
		named
	)


## Builds a squad on a fresh tile of [param terrain_type] (no grid).
static func make_squad(id: String, unit_type_id: String, officer: Officer, terrain_type: TerrainSystem.TerrainType) -> Squad:
	var tile: TerrainTile = TerrainTileScript.new(terrain_type)
	return SquadScript.create(id, unit_type_id, combat_config(), officer, tile)


## Builds a battle-ready squad: side, cube position, morale initialized.
## If [param grid] is given, the squad is placed on it (occupancy + tile).
static func battle_squad(id: String, side: Squad.Side, position: Vector3i, officer: Officer = null, unit_type_id: String = "swordsman", grid: BattleGrid = null) -> Squad:
	var squad: Squad = SquadScript.create(id, unit_type_id, combat_config(), officer)
	squad.side = side
	squad.init_morale(morale_config())
	if grid != null:
		grid.place_squad(squad, position)
	else:
		squad.position = position
	return squad
