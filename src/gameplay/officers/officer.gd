class_name Officer
extends RefCounted
## A single officer's five-stat block (WAR, LDR, INT, POL, CHR).
##
## Implements design/gdd/officer-stats.md. Officer Stats is the foundational
## data layer: dependent systems READ stats but must never WRITE them.
## The public [method set_stat] is intentionally a rejection stub (logs an
## error and returns false) — all mutation goes through OfficerRegistry,
## which is the only system allowed to call [method _apply_growth].

## The five officer stats. GDD interface contract maps to accessors:
## officer.war(), officer.ldr(), officer.intel() (GDD: officer.int() —
## `int` is reserved in GDScript), officer.pol(), officer.chr().
enum Stat { WAR, LDR, INT, POL, CHR }

## Stat values are clamped to [STAT_MIN, STAT_MAX] under all circumstances.
const STAT_MIN := 1
const STAT_MAX := 100

const _STAT_NAME_LOOKUP: Dictionary = {
	"WAR": Stat.WAR,
	"LDR": Stat.LDR,
	"INT": Stat.INT,
	"POL": Stat.POL,
	"CHR": Stat.CHR,
}

## Unique officer identifier (snake_case, e.g. "kaster").
var id: String = ""
## Display name shown in UI (e.g. "Zhuge Jian").
var display_name: String = ""
## True for the 7 designed officers; false for generic recruits.
## Only named officers receive act-transition growth.
var is_named: bool = false
## Signature Passive Ability name (named officers) or generic passive (optional).
var signature_passive: String = ""
## res:// path to the officer's base portrait PNG. Empty string = no portrait.
var portrait_path: String = ""

var _stats: Dictionary = {}


## Builds an officer from raw stat values, clamping each to [1, 100].
static func create(p_id: String, p_name: String, stats: Dictionary, p_is_named: bool, p_passive: String = "") -> Officer:
	var officer := Officer.new()
	officer.id = p_id
	officer.display_name = p_name
	officer.is_named = p_is_named
	officer.signature_passive = p_passive
	for stat: Stat in Stat.values():
		var key: String = (Stat.keys()[stat] as String).to_lower()
		officer._stats[stat] = clampi(int(stats.get(key, STAT_MIN)), STAT_MIN, STAT_MAX)
	officer.portrait_path = String(stats.get("portrait_path", ""))
	return officer


## Returns the current value of [param stat] in [1, 100].
func get_stat(stat: Stat) -> int:
	if not _stats.has(stat):
		push_error("Officer %s: unknown stat %d queried — returning 0" % [id, stat])
		return 0
	return _stats[stat]


## Returns a stat by its string name ("WAR", "LDR", "INT", "POL", "CHR").
## Invalid names (e.g. "FEAR") log an error and return 0 (GDD safe default).
func get_stat_by_name(stat_name: String) -> int:
	var key := stat_name.to_upper()
	if not _STAT_NAME_LOOKUP.has(key):
		push_error("Officer %s: invalid stat type '%s' queried — returning 0" % [id, stat_name])
		return 0
	return get_stat(_STAT_NAME_LOOKUP[key])


## Warfare — combat prowess, melee/ranged damage, duel effectiveness.
func war() -> int:
	return get_stat(Stat.WAR)


## Leadership — squad control, morale influence, unit cohesion (defense).
func ldr() -> int:
	return get_stat(Stat.LDR)


## Intelligence — strategic insight, intel cost reduction, stratagems.
## (GDD contract name is officer.int(); `int` is a reserved word in GDScript.)
func intel() -> int:
	return get_stat(Stat.INT)


## Politics — governance output, economy, diplomatic persuasion.
func pol() -> int:
	return get_stat(Stat.POL)


## Charisma — recruitment, morale recovery, loyalty influence.
func chr() -> int:
	return get_stat(Stat.CHR)


## REJECTED BY DESIGN. Dependent systems must never modify officer stats
## (GDD data contract). Always logs an error and returns false; the stat
## value is left unchanged. Growth is owned by OfficerRegistry only.
func set_stat(stat: Stat, _value: int) -> bool:
	push_error(
		"Officer %s: set_stat(%s) rejected — officer stats are read-only for dependent systems; growth is owned by OfficerRegistry"
		% [id, Stat.keys()[stat]]
	)
	return false


## INTERNAL — OfficerRegistry only. Applies act-transition growth with
## clamping (a stat at 100 stays 100). Do not call from dependent systems.
func _apply_growth(stat: Stat, amount: int) -> void:
	if not _stats.has(stat):
		push_error("Officer %s: growth on unknown stat %d ignored" % [id, stat])
		return
	_stats[stat] = clampi(_stats[stat] + amount, STAT_MIN, STAT_MAX)
