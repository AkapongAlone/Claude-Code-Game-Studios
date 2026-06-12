class_name MoraleSystem
extends RefCounted
## Per-squad morale: damage triggers, leadership auras, recovery, and the
## 2-pass rout cascade (design/gdd/morale-system.md).
##
## Runs once per round after Combat Resolution:
##   Pass 1 — casualties + flank + officer loss + queued (Vital Strike)
##   Pass 2 — witnessing-rout damage from squads that broke in Pass 1
##   (hard cap: no Pass 3 — squads that would break later keep their value)
## Recovery runs at end of round for squads that took zero morale damage.
## All values come from assets/data/morale.json.

## One morale event for HUD display.
class MoraleEvent:
	extends RefCounted
	var squad: Squad
	var damage: int = 0
	var newly_broken: bool = false

var _casualty_sensitivity: float = 50.0
var _flank_penalty: int = 10
var _officer_loss_penalty: int = 30
var _witnessing_penalty: int = 10
var _witnessing_radius: int = 2
var _aura_protection_rate: float = 0.25
var _recovery_divisor: int = 25
var _aura_brackets: Array = []
## Injected PassiveRegistry (may be null — system works without passives).
var passives: PassiveRegistry = null


static func from_config(config: Dictionary) -> MoraleSystem:
	var system := MoraleSystem.new()
	system._casualty_sensitivity = float(config.get("casualty_sensitivity", 50))
	system._flank_penalty = int(config.get("flank_morale_penalty", 10))
	system._officer_loss_penalty = int(config.get("officer_loss_penalty", 30))
	system._witnessing_penalty = int(config.get("witnessing_penalty", 10))
	system._witnessing_radius = int(config.get("witnessing_radius", 2))
	system._aura_protection_rate = float(config.get("aura_protection_rate", 0.25))
	system._recovery_divisor = int(config.get("recovery_chr_divisor", 25))
	system._aura_brackets = config.get("aura_radius_brackets", [
		{ "min_ldr": 90, "radius": 4 },
		{ "min_ldr": 75, "radius": 3 },
		{ "min_ldr": 50, "radius": 2 },
		{ "min_ldr": 0, "radius": 1 },
	])
	return system


## F-1: aura radius bracket from LDR (<50→1, 50–74→2, 75–89→3, ≥90→4).
func aura_radius(ldr: int) -> int:
	for bracket: Dictionary in _aura_brackets:
		if ldr >= int(bracket.get("min_ldr", 0)):
			return int(bracket.get("radius", 1))
	return 1


## F-2: morale recovered per quiet turn = floor(CHR / 25).
func recovery_amount(chr: int) -> int:
	return chr / _recovery_divisor


## F-3: casualty morale damage = floor(hp_lost_pct × sensitivity).
func casualty_damage(hp_lost: float, max_hp: float) -> int:
	if max_hp <= 0.0:
		return 0
	return int(floorf(hp_lost / max_hp * _casualty_sensitivity))


## Highest-LDR friendly officer whose aura covers [param squad] (including
## the squad's own officer — radius always ≥ 1 covers distance 0).
## Tiebreak on equal LDR: lower squad id. BROKEN squads project no aura.
## Returns the aura officer, or null when no aura covers the squad.
func aura_officer_for(squad: Squad, squads: Array) -> Officer:
	var best: Officer = null
	var best_source: Squad = null
	for source: Squad in squads:
		if source.officer == null or not source.is_active():
			continue
		if source.side != squad.side or source.morale_state == Squad.MoraleState.BROKEN:
			continue
		if CubeHex.distance(source.position, squad.position) > aura_radius(source.officer.ldr()):
			continue
		if best == null \
				or source.officer.ldr() > best.ldr() \
				or (source.officer.ldr() == best.ldr() and source.id < best_source.id):
			best = source.officer
			best_source = source
	return best


## Morale Resolution Phase: applies all four triggers with the 2-pass
## cascade cap. Returns Array[MoraleEvent] for the HUD.
func resolve_morale_phase(squads: Array) -> Array:
	var events: Array = []
	var pass1_broken: Array = []

	# --- Pass 1: casualties, flank, officer loss, queued Vital Strike ---
	for squad: Squad in squads:
		if not squad.is_active() or squad.morale_state == Squad.MoraleState.BROKEN:
			continue
		if passives != null and passives.is_morale_immune(squad):
			continue
		var raw := casualty_damage(squad.hp_lost_this_turn, squad.max_hp)
		if squad.is_flanked_this_turn and not _flank_immune(squad, squads):
			raw += _flank_penalty
		if squad.officer_lost_this_turn:
			raw += _officer_loss_penalty
		raw += squad.pending_morale_damage
		squad.pending_morale_damage = 0
		if raw <= 0:
			continue
		var total := _apply_aura(raw, squad, squads)
		squad.took_morale_damage_this_turn = true
		var was_broken := squad.morale_state == Squad.MoraleState.BROKEN
		squad.set_morale(squad.morale - total)
		var event := MoraleEvent.new()
		event.squad = squad
		event.damage = total
		event.newly_broken = not was_broken and squad.morale_state == Squad.MoraleState.BROKEN
		events.append(event)
		if event.newly_broken:
			pass1_broken.append(squad)

	# --- Pass 2: witnessing rout (friendly routs within radius); no Pass 3 ---
	if not pass1_broken.is_empty():
		for squad: Squad in squads:
			if not squad.is_active() or squad.morale_state == Squad.MoraleState.BROKEN:
				continue
			if passives != null and passives.is_morale_immune(squad):
				continue
			var witnessed := 0
			for broken: Squad in pass1_broken:
				if broken.side == squad.side and broken != squad \
						and CubeHex.distance(broken.position, squad.position) <= _witnessing_radius:
					witnessed += 1
			if witnessed == 0:
				continue
			var total := _apply_aura(witnessed * _witnessing_penalty, squad, squads)
			squad.took_morale_damage_this_turn = true
			var was_broken := squad.morale_state == Squad.MoraleState.BROKEN
			squad.set_morale(squad.morale - total)
			var event := MoraleEvent.new()
			event.squad = squad
			event.damage = total
			event.newly_broken = not was_broken and squad.morale_state == Squad.MoraleState.BROKEN
			events.append(event)
			# Pass 2 BROKEN entries generate no further witnessing (cascade cap).
	return events


## Recovery Phase: non-BROKEN squads that took zero morale damage recover
## floor(CHR / 25) using the covering aura officer's CHR (own officer
## qualifies; officer-less squads recover only inside a friendly aura).
func recovery_phase(squads: Array) -> void:
	for squad: Squad in squads:
		if not squad.is_active() or squad.morale_state == Squad.MoraleState.BROKEN:
			continue
		if squad.took_morale_damage_this_turn:
			continue
		var officer := aura_officer_for(squad, squads)
		if officer == null:
			continue
		var amount := recovery_amount(officer.chr())
		if amount > 0:
			squad.set_morale(squad.morale + amount)


## F-7 aura reduction: floor applied ONCE to the combined per-pass total.
func _apply_aura(raw: int, squad: Squad, squads: Array) -> int:
	if aura_officer_for(squad, squads) != null:
		return int(floorf(raw * (1.0 - _aura_protection_rate)))
	return raw


func _flank_immune(squad: Squad, squads: Array) -> bool:
	return passives != null and passives.is_flank_morale_immune(squad, squads)
