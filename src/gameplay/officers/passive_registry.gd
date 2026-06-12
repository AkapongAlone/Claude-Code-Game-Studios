class_name PassiveRegistry
extends RefCounted
## Officer passive abilities: registration lifecycle + battle hooks
## (design/gdd/officer-passive-ability.md).
##
## Owns all passive logic; other systems call hooks and never implement
## passive behavior themselves. Battle-scope hooks implemented for MVP:
## Juggernaut (morale immunity), Old Guard (adjacent flank-morale immunity),
## Shadow Work (forest melee flank override), Vital Strike (kill morale
## blast), Stratagem (+1 vision all squads), Heirloom Blade (hidden damage
## ceiling proc). Campaign-scope passives (Treatises, Quartermaster) and
## Read the Field register flags only — their consumers are post-MVP.
##
## SECURITY CONSTRAINT: "heirloom_blade" must NEVER appear in player-facing
## UI. display_passives() filters on is_player_visible upstream so the
## rendering layer is unaware of its existence.

var _config: Dictionary = {}
var _combat_config: Dictionary = {}
## officer_id → Array[Dictionary] of active passive entries
var _active: Dictionary = {}


static func from_config(passive_config: Dictionary, combat_config: Dictionary = {}) -> PassiveRegistry:
	var registry := PassiveRegistry.new()
	registry._config = passive_config
	registry._combat_config = combat_config
	return registry


## Registers passives for every officer present in [param squads]
## (battle start). Officers not in the config register nothing.
func register_battle(squads: Array) -> void:
	_active.clear()
	var all_passives: Dictionary = _config.get("officer_passives", {})
	for squad: Squad in squads:
		if squad.officer != null and all_passives.has(squad.officer.id):
			_active[squad.officer.id] = all_passives[squad.officer.id]


## Deregisters an officer's passives (incapacitated, killed, or absent).
func deregister_officer(officer_id: String) -> void:
	_active.erase(officer_id)


## Clears the registry (battle end).
func clear() -> void:
	_active.clear()


func has_passive(officer_id: String, passive_id: String) -> bool:
	for entry: Dictionary in _active.get(officer_id, []):
		if String(entry.get("id", "")) == passive_id:
			return true
	return false


## Player-visible passive names for an officer — filters hidden passives
## upstream so the UI never sees them (Heirloom Blade constraint).
func display_passives(officer: Officer) -> Array[String]:
	var names: Array[String] = []
	if officer == null:
		return names
	var all_passives: Dictionary = _config.get("officer_passives", {})
	for entry: Dictionary in all_passives.get(officer.id, []):
		if bool(entry.get("is_player_visible", true)):
			names.append(String(entry.get("name", "")))
	return names


## Juggernaut hook: all morale damage is skipped for this squad.
func is_morale_immune(squad: Squad) -> bool:
	return squad.officer != null and has_passive(squad.officer.id, "juggernaut")


## Old Guard hook: true when a friendly Old Guard officer's squad is within
## the immunity radius (1 hex). Does NOT apply to the Old Guard squad itself.
func is_flank_morale_immune(squad: Squad, squads: Array) -> bool:
	var radius: int = int(_config.get("old_guard_radius", 1))
	for source: Squad in squads:
		if source == squad or source.side != squad.side or not source.is_active():
			continue
		if source.morale_state == Squad.MoraleState.BROKEN or source.officer == null:
			continue
		if not has_passive(source.officer.id, "old_guard"):
			continue
		if CubeHex.distance(source.position, squad.position) <= radius:
			return true
	return false


## Shadow Work hook (F-2): melee attack initiated FROM a forest hex by the
## Shadow Work officer is always a flank (max(flanking_mod, 1.3) — no stack).
func shadow_work_applies(attacker: Squad, attacker_in_forest: bool) -> bool:
	return attacker.officer != null \
		and has_passive(attacker.officer.id, "shadow_work") \
		and attacker.attack_kind == Squad.AttackKind.MELEE \
		and attacker_in_forest


## Vital Strike hook (F-4): on an HP-kill by the Vital Strike officer,
## queue −10 morale to every enemy squad within 2 hexes of the kill site.
## Queued damage is processed inside the normal cascade passes.
## Returns the affected squads (for HUD feedback).
func on_kill(killer: Squad, killed: Squad, squads: Array) -> Array:
	var affected: Array = []
	if killer.officer == null or not has_passive(killer.officer.id, "vital_strike"):
		return affected
	var damage: int = int(_config.get("vital_strike_morale_damage", 10))
	var radius: int = int(_config.get("vital_strike_radius", 2))
	for squad: Squad in squads:
		if squad.side == killer.side or squad == killed or not squad.is_active():
			continue
		if CubeHex.distance(squad.position, killed.position) <= radius:
			squad.pending_morale_damage += damage
			affected.append(squad)
	return affected


## Stratagem hook (F-5): +1 vision for ALL friendly squads while the
## Stratagem officer is present and not BROKEN.
func vision_bonus_for_side(side: Squad.Side, squads: Array) -> int:
	for squad: Squad in squads:
		if squad.side != side or not squad.is_active() or squad.officer == null:
			continue
		if squad.morale_state == Squad.MoraleState.BROKEN:
			continue
		if has_passive(squad.officer.id, "stratagem"):
			return int(_config.get("stratagem_vision_bonus", 1))
	return 0


## Heirloom Blade hook (F-3): rolls the hidden proc for an attack.
## Returns the ceiling damage when the proc fires, or -1.0 otherwise.
## The ceiling uses the officer's ACTUAL WAR and formula maximums — never
## an impossible number (ambiguity constraint).
func roll_blade_proc(attacker: Squad, rng: RandomNumberGenerator) -> float:
	if attacker.officer == null or not has_passive(attacker.officer.id, "heirloom_blade"):
		return -1.0
	if rng.randf() >= float(_config.get("blade_proc_rate", 0.05)):
		return -1.0
	return blade_damage_ceiling(attacker)


## F-3 damage ceiling: floor(unit_base × scaling(WAR) × 1.25 × 1.3).
## Kaster (WAR 82): swordsman 91, musketeer 103 (GDD AC 12–13).
func blade_damage_ceiling(attacker: Squad) -> float:
	var war: int = attacker.officer.war() if attacker.officer != null else 0
	var divisor: float
	if attacker.attack_kind == Squad.AttackKind.RANGED:
		divisor = float(_combat_config.get("ranged_war_divisor", 100.0))
	else:
		divisor = float(_combat_config.get("melee_war_divisor", 200.0))
	var scaling := 1.0 + war / divisor
	var max_terrain: float = float(_config.get("blade_max_terrain_mod", 1.25))
	var max_flank: float = float(_config.get("blade_max_flank_mod", 1.3))
	return floorf(attacker.unit_base * scaling * max_terrain * max_flank)
