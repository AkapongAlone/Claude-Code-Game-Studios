class_name Squad
extends RefCounted
## A combat squad: HP pool, unit type, commanding officer, hex position,
## facing, morale, and per-turn battle flags.
##
## State ownership follows the GDDs: Hex Movement owns position/AP flags,
## Facing & Flank owns facing_direction, Morale owns morale value/state,
## Fog of War owns visibility fields. Squad is the shared data carrier.

## How this squad attacks (combat-resolution.md).
enum AttackKind { RANGED, MELEE }

## Morale states (morale-system.md): STEADY ≥30, SHAKEN 10–29, BROKEN <10.
enum MoraleState { STEADY, SHAKEN, BROKEN }

## Which army the squad belongs to.
enum Side { PLAYER, ENEMY }

## Fog visibility states for enemy squads (fog-of-war.md).
enum Visibility { HIDDEN, VISIBLE, PREVIOUSLY_SEEN }

## Unique squad identifier.
var id: String = ""
## Unit type key into combat.json (e.g. "archer", "swordsman").
var unit_type_id: String = ""
## Ranged or melee resolution path.
var attack_kind: AttackKind = AttackKind.MELEE
## Unit class for AP pool and vision: "INF" | "LI" | "CAV" | "ART".
var unit_class: String = "INF"
## Attack range in hexes (ranged: 2–4, melee: 1).
var range_min: int = 1
var range_max: int = 1
## Squad-type base damage before modifiers.
var unit_base: int = 0
## HP pool. hp clamps to [0, max_hp]; 0 = killed.
var max_hp: float = 0.0
var hp: float = 0.0
## Commanding officer, or null (officer-less squads are morale-brittle).
var officer: Officer = null
## Army side. (Annotation is qualified — bare `Side` collides with Godot's
## global Side enum from @GlobalScope.)
var side: Squad.Side = Squad.Side.PLAYER

# --- Spatial state (owned by Hex Movement / Facing & Flank) ---
## Current hex in cube coordinates.
var position: Vector3i = Vector3i.ZERO
## Facing direction index [0–5], clockwise from East.
var facing_direction: int = 0
## The terrain tile under this squad (assigned by the battle grid).
var tile: TerrainTile = null

# --- Morale state (owned by Morale System) ---
## Current morale value [0, 100]. Use set_morale() so state stays derived.
var morale: int = 100
var morale_state: MoraleState = MoraleState.STEADY
var _steady_threshold: int = 30
var _broken_threshold: int = 10

# --- Per-round flags (reset by begin_round) ---
var ap_pool: int = 0
var ap_remaining: int = 0
var moved_this_turn: bool = false
var attacked_this_turn: bool = false
var crossed_ford_this_turn: bool = false
var is_flanked_this_turn: bool = false
var hp_lost_this_turn: float = 0.0
var officer_lost_this_turn: bool = false
## Queued out-of-phase morale damage (e.g. Thane's Vital Strike).
var pending_morale_damage: int = 0
var took_morale_damage_this_turn: bool = false

# --- Routing state (owned by Hex Movement, signalled by Morale) ---
var has_routing_target: bool = false
var routing_target: Vector3i = Vector3i.ZERO
var routing_blocked_turns: int = 0
var is_off_map: bool = false

# --- Fog of War state (enemy squads only; owned by Fog of War) ---
var visibility_state: Visibility = Visibility.HIDDEN
var last_known_position: Vector3i = Vector3i.ZERO
var last_known_unit_type: String = ""
var last_seen_turn: int = -1

# --- Passive / duel flags ---
## Sum of active passive vision bonuses (e.g. Bon's Stratagem +1).
var vision_bonus: int = 0
## True once this squad's officer has issued a field challenge this battle.
var challenge_used: bool = false


## Builds a squad of [param p_unit_type_id] from a combat.json config.
## Returns null (and logs an error) for unknown unit types.
static func create(p_id: String, p_unit_type_id: String, combat_config: Dictionary, p_officer: Officer = null, p_tile: TerrainTile = null) -> Squad:
	var unit_types: Dictionary = combat_config.get("unit_types", {})
	if not unit_types.has(p_unit_type_id):
		push_error("Squad: unknown unit type '%s'" % p_unit_type_id)
		return null
	var unit: Dictionary = unit_types[p_unit_type_id]
	var squad := Squad.new()
	squad.id = p_id
	squad.unit_type_id = p_unit_type_id
	squad.attack_kind = AttackKind.RANGED if String(unit.get("attack", "melee")) == "ranged" else AttackKind.MELEE
	squad.unit_class = String(unit.get("unit_class", "INF"))
	squad.range_min = int(unit.get("range_min", 1))
	squad.range_max = int(unit.get("range_max", 1))
	squad.unit_base = int(unit.get("unit_base", 0))
	squad.max_hp = float(unit.get("max_hp", 0))
	squad.hp = squad.max_hp
	squad.officer = p_officer
	squad.tile = p_tile
	return squad


## Configures morale thresholds and starting value (morale-system.md:
## officer-led 100, officer-less 70; scenarios may override).
func init_morale(morale_config: Dictionary, override_start: int = -1) -> void:
	_steady_threshold = int(morale_config.get("steady_threshold", 30))
	_broken_threshold = int(morale_config.get("broken_threshold", 10))
	var start: int
	if override_start >= 0:
		start = override_start
	elif officer != null:
		start = int(morale_config.get("officer_morale_start", 100))
	else:
		start = int(morale_config.get("officerless_morale_start", 70))
	morale = clampi(start, 0, 100)
	morale_state = _derive_state()


## Sets the morale value (clamped [0, 100]) and re-derives the state.
## BROKEN is terminal: once routing is committed, no value change can
## restore SHAKEN/STEADY (morale-system.md state machine).
func set_morale(value: int) -> void:
	morale = clampi(value, 0, 100)
	if morale_state == MoraleState.BROKEN:
		return
	morale_state = _derive_state()


func _derive_state() -> MoraleState:
	if morale >= _steady_threshold:
		return MoraleState.STEADY
	if morale >= _broken_threshold:
		return MoraleState.SHAKEN
	return MoraleState.BROKEN


## Resets all per-round flags at round start (Movement Phase reset).
func begin_round() -> void:
	ap_remaining = ap_pool
	moved_this_turn = false
	attacked_this_turn = false
	crossed_ford_this_turn = false
	is_flanked_this_turn = false
	hp_lost_this_turn = 0.0
	officer_lost_this_turn = false
	pending_morale_damage = 0
	took_morale_damage_this_turn = false


## Applies HP damage; clamps at 0 and accumulates hp_lost_this_turn for the
## Morale System's casualty trigger.
func take_damage(amount: float) -> void:
	var before := hp
	hp = clampf(hp - amount, 0.0, max_hp)
	hp_lost_this_turn += before - hp


## True when HP has reached 0 — the squad is removed from the map (death,
## not rout: no campaign recovery, no witnessing morale event).
func is_dead() -> bool:
	return hp <= 0.0


## True while the squad is on the map and able to act (not dead, not off-map).
func is_active() -> bool:
	return not is_dead() and not is_off_map


## Removes the officer (incapacitated in a duel or killed). Fires the
## officer-loss morale trigger unless the squad is already BROKEN.
func lose_officer() -> void:
	if officer == null:
		return
	officer = null
	if morale_state != MoraleState.BROKEN:
		officer_lost_this_turn = true
