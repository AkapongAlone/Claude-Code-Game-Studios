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

## Fixed seed: tests must be deterministic across runs.
const DEFAULT_SEED := 13371337


static func officers_config() -> Dictionary:
	return ConfigLoaderScript.load_json("res://assets/data/officers.json")


static func terrain_config() -> Dictionary:
	return ConfigLoaderScript.load_json("res://assets/data/terrain.json")


static func combat_config() -> Dictionary:
	return ConfigLoaderScript.load_json("res://assets/data/combat.json")


static func officer_registry() -> OfficerRegistry:
	return OfficerRegistryScript.from_config(officers_config())


static func terrain_system() -> TerrainSystem:
	return TerrainSystemScript.from_config(terrain_config())


static func combat_resolver(terrain: TerrainSystem = null) -> CombatResolver:
	if terrain == null:
		terrain = terrain_system()
	return CombatResolverScript.from_config(combat_config(), terrain)


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


## Builds a squad on a fresh tile of [param terrain_type].
static func make_squad(id: String, unit_type_id: String, officer: Officer, terrain_type: TerrainSystem.TerrainType) -> Squad:
	var tile: TerrainTile = TerrainTileScript.new(terrain_type)
	return SquadScript.create(id, unit_type_id, combat_config(), officer, tile)
