class_name OfficerRegistry
extends RefCounted
## Owns every Officer instance and all stat mutation (initialization,
## generic recruitment, act-transition growth, battle deferral).
##
## Implements design/gdd/officer-stats.md. Dependent systems query officers
## via [method get_officer] and read stats; they never write. Growth fired
## during an active battle is deferred and applied at [method end_battle]
## (GDD edge case: act transition during active battle).

const OfficerScript := preload("res://src/gameplay/officers/officer.gd")

var _officers: Dictionary = {}
var _archetypes: Dictionary = {}
var _stat_min: int = 1
var _stat_max: int = 100
var _battle_active: bool = false
var _pending_growth: Array = []
var _generic_counter: int = 0


## Builds the registry from a parsed officers.json Dictionary
## (see assets/data/officers.json). Inject fixture data in tests.
static func from_config(config: Dictionary) -> OfficerRegistry:
	var registry := OfficerRegistry.new()
	registry._stat_min = int(config.get("stat_min", 1))
	registry._stat_max = int(config.get("stat_max", 100))
	registry._archetypes = config.get("archetypes", {})
	for entry: Dictionary in config.get("named_officers", []):
		var officer := OfficerScript.create(
			String(entry.get("id", "")),
			String(entry.get("name", "")),
			entry,
			true,
			String(entry.get("signature_passive", ""))
		)
		if officer.id.is_empty():
			push_error("OfficerRegistry: named officer entry missing id — skipped")
			continue
		registry._officers[officer.id] = officer
	return registry


## Convenience factory: loads assets/data/officers.json from disk.
static func from_file(path: String = "res://assets/data/officers.json") -> OfficerRegistry:
	return from_config(ConfigLoader.load_json(path))


## Returns the officer with [param officer_id], or null if no such officer
## exists (GDD: query before initialization returns null; callers must
## handle null gracefully).
func get_officer(officer_id: String) -> Officer:
	return _officers.get(officer_id)


## All registered officers (named + recruited generics).
func get_all_officers() -> Array:
	return _officers.values()


## Recruits a generic officer of [param archetype_id].
## Each stat is archetype baseline + random(-variance, +variance), clamped
## to [1, 100]. Invalid archetype logs an error and returns null — no
## fallback archetype is assigned (GDD edge case).
## [param rng] is injected so tests can seed deterministically.
func recruit_generic(archetype_id: String, rng: RandomNumberGenerator) -> Officer:
	if not _archetypes.has(archetype_id):
		push_error("OfficerRegistry: invalid archetype '%s' — recruitment failed" % archetype_id)
		return null
	var archetype: Dictionary = _archetypes[archetype_id]
	var baseline: Dictionary = archetype.get("stats", {})
	var variance: int = int(archetype.get("variance", 2))
	var rolled: Dictionary = {}
	for key: String in ["war", "ldr", "int", "pol", "chr"]:
		var base: int = int(baseline.get(key, _stat_min))
		rolled[key] = clampi(base + rng.randi_range(-variance, variance), _stat_min, _stat_max)
	_generic_counter += 1
	var officer := OfficerScript.create(
		"generic_%s_%03d" % [archetype_id, _generic_counter],
		"%s Officer %d" % [String(archetype.get("name", archetype_id)), _generic_counter],
		rolled,
		false
	)
	_officers[officer.id] = officer
	return officer


## Marks a tactical battle as active. Growth fired while active is deferred.
func begin_battle() -> void:
	_battle_active = true


## Ends the active battle and applies any deferred act-transition growth.
func end_battle() -> void:
	_battle_active = false
	if _pending_growth.is_empty():
		return
	var deferred := _pending_growth
	_pending_growth = []
	apply_act_growth(deferred)


## Applies an act-transition growth plan. Each entry is a Dictionary:
## { "officer_id": String, "stat": Officer.Stat, "amount": int }.
## Amounts are designer-authored (rolled in [1, 3] via [method roll_growth]);
## application is exact and clamped to [1, 100]. Generic officers never grow.
## If a battle is active, the whole plan is deferred until end_battle().
func apply_act_growth(growth_plan: Array) -> void:
	if _battle_active:
		_pending_growth.append_array(growth_plan)
		return
	for entry: Dictionary in growth_plan:
		var officer: Officer = get_officer(String(entry.get("officer_id", "")))
		if officer == null:
			push_error("OfficerRegistry: growth for unknown officer '%s' ignored" % entry.get("officer_id", ""))
			continue
		if not officer.is_named:
			push_error("OfficerRegistry: growth rejected for generic officer '%s' — generics do not grow" % officer.id)
			continue
		var amount: int = int(entry.get("amount", 0))
		if amount < 0:
			push_error("OfficerRegistry: negative growth %d for '%s' rejected" % [amount, officer.id])
			continue
		officer._apply_growth(int(entry.get("stat", -1)) as Officer.Stat, amount)


## True while a battle is in progress (growth will be deferred).
func is_battle_active() -> bool:
	return _battle_active


## Rolls a growth amount in [growth_min, growth_max] (GDD: random(1, 3)).
## RNG is injected for deterministic tests.
static func roll_growth(rng: RandomNumberGenerator, growth_min: int = 1, growth_max: int = 3) -> int:
	return rng.randi_range(growth_min, growth_max)
