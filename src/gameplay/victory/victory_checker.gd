class_name VictoryChecker
extends RefCounted
## Per-turn battle end evaluation (design/gdd/victory-defeat-conditions.md).
##
## Evaluation order (fires once per turn, after Routing Resolution):
##   1. Hard defeats (LOSE_VIP, ENEMY_HOLDS_OBJECTIVE)
##   2. Victory conditions (ROUTE_ENEMY, HOLD_OBJECTIVE, SURVIVE_TURNS,
##      ELIMINATE_TARGET) — victory_mode "any" | "all"
##   3. Soft defeat (PLAYER_ROUTED)
##   4. Turn limit (EXCEED_TURN_LIMIT, strictly current_turn > max_turns)
## Data-driven via a BattleDefinition dictionary; the engine is generic.

enum Result { ONGOING, VICTORY, DEFEAT, DRAW }

## Battle-end report consumed by the HUD and (later) the campaign layer.
class BattleResult:
	extends RefCounted
	var result: Result = Result.ONGOING
	var trigger_type: String = ""
	var end_turn: int = 0
	var route_fraction_player: float = 0.0
	var route_fraction_enemy: float = 0.0

var _victory_conditions: Array = []
var _defeat_conditions: Array = []
var _victory_mode: String = "any"
var _starting_player: int = 0
var _starting_enemy: int = 0
var _dead: Dictionary = { Squad.Side.PLAYER: 0, Squad.Side.ENEMY: 0 }
var _routed_off: Dictionary = { Squad.Side.PLAYER: 0, Squad.Side.ENEMY: 0 }
## officer_id → Squad for LOSE_VIP / ELIMINATE_TARGET lookups
var _vip_squads: Dictionary = {}
## objective hex (Vector3i) → consecutive hold turns per side
var _hold_player: Dictionary = {}
var _hold_enemy: Dictionary = {}


## Builds a checker from a BattleDefinition. starting_squads counts are
## locked at battle start and never change (denominator rule).
static func from_definition(definition: Dictionary, starting_player: int, starting_enemy: int) -> VictoryChecker:
	var checker := VictoryChecker.new()
	checker._victory_conditions = definition.get("victory_conditions", [])
	checker._defeat_conditions = definition.get("defeat_conditions", [])
	checker._victory_mode = String(definition.get("victory_mode", "any"))
	checker._starting_player = starting_player
	checker._starting_enemy = starting_enemy
	if checker._victory_conditions.is_empty() and checker._defeat_conditions.is_empty():
		push_error("VictoryChecker: BattleDefinition has no conditions — battle can never end")
	return checker


## Registers the squad commanded by a VIP / eliminate-target officer at
## battle start (LOSE_VIP tracks the squad, not the officer object).
func register_officer_squad(officer_id: String, squad: Squad) -> void:
	_vip_squads[officer_id] = squad


## Records a squad killed at HP 0 (separate accumulator — death removal
## fires no rout event but still counts toward route_fraction).
func record_death(side: Squad.Side) -> void:
	_dead[side] = int(_dead[side]) + 1


## Records a BROKEN squad that exited the map edge.
func record_rout_exit(side: Squad.Side) -> void:
	_routed_off[side] = int(_routed_off[side]) + 1


## F-1: route_fraction = (broken_on_map + routed_off_map + dead) / starting.
## starting = 0 → defined as 1.0 (defensive division-by-zero rule).
func route_fraction(side: Squad.Side, squads: Array) -> float:
	var starting := _starting_player if side == Squad.Side.PLAYER else _starting_enemy
	if starting <= 0:
		return 1.0
	var broken_on_map := 0
	for squad: Squad in squads:
		if squad.side == side and squad.is_active() and squad.morale_state == Squad.MoraleState.BROKEN:
			broken_on_map += 1
	return float(broken_on_map + int(_routed_off[side]) + int(_dead[side])) / float(starting)


## Advances objective hold counters for this turn (call before evaluate).
## Control: ≥1 non-BROKEN friendly squad on the hex AND 0 enemy squads.
## Loss of control fully resets the counter.
func update_objectives(squads: Array) -> void:
	for condition: Dictionary in _victory_conditions + _defeat_conditions:
		var type := String(condition.get("type", ""))
		if type != "HOLD_OBJECTIVE" and type != "ENEMY_HOLDS_OBJECTIVE":
			continue
		var hex := _parse_hex(condition.get("hex_coord"))
		var player_on := 0
		var enemy_on := 0
		for squad: Squad in squads:
			if not squad.is_active() or squad.position != hex:
				continue
			if squad.morale_state == Squad.MoraleState.BROKEN:
				continue
			if squad.side == Squad.Side.PLAYER:
				player_on += 1
			else:
				enemy_on += 1
		if player_on > 0 and enemy_on == 0:
			_hold_player[hex] = int(_hold_player.get(hex, 0)) + 1
			_hold_enemy[hex] = 0
		elif enemy_on > 0 and player_on == 0:
			_hold_enemy[hex] = int(_hold_enemy.get(hex, 0)) + 1
			_hold_player[hex] = 0
		else:
			_hold_player[hex] = 0
			_hold_enemy[hex] = 0


## Full evaluation pass. Returns a BattleResult (Result.ONGOING when no
## condition triggered).
func evaluate(squads: Array, current_turn: int) -> BattleResult:
	var report := BattleResult.new()
	report.end_turn = current_turn
	report.route_fraction_player = route_fraction(Squad.Side.PLAYER, squads)
	report.route_fraction_enemy = route_fraction(Squad.Side.ENEMY, squads)

	# 1. Hard defeats
	for condition: Dictionary in _defeat_conditions:
		var type := String(condition.get("type", ""))
		if type == "LOSE_VIP" and _squad_eliminated(String(condition.get("vip_officer_id", ""))):
			return _ended(report, Result.DEFEAT, type)
		if type == "ENEMY_HOLDS_OBJECTIVE":
			var hex := _parse_hex(condition.get("hex_coord"))
			if int(_hold_enemy.get(hex, 0)) >= int(condition.get("enemy_hold_turns", 1)):
				return _ended(report, Result.DEFEAT, type)

	# 2. Victory conditions
	var met := 0
	var first_met := ""
	for condition: Dictionary in _victory_conditions:
		if _victory_met(condition, report, current_turn):
			met += 1
			if first_met.is_empty():
				first_met = String(condition.get("type", ""))
	var victory := false
	if _victory_mode == "all":
		victory = met > 0 and met == _victory_conditions.size()
	else:
		victory = met > 0
	if victory:
		return _ended(report, Result.VICTORY, first_met)

	# 3. Soft defeat
	for condition: Dictionary in _defeat_conditions:
		if String(condition.get("type", "")) == "PLAYER_ROUTED":
			if report.route_fraction_player >= float(condition.get("threshold", 0.50)):
				return _ended(report, Result.DEFEAT, "PLAYER_ROUTED")

	# 4. Turn limit (strictly greater than)
	for condition: Dictionary in _defeat_conditions:
		if String(condition.get("type", "")) == "EXCEED_TURN_LIMIT":
			if current_turn > int(condition.get("max_turns", 20)):
				return _ended(report, Result.DEFEAT, "EXCEED_TURN_LIMIT")

	return report


func _victory_met(condition: Dictionary, report: BattleResult, current_turn: int) -> bool:
	match String(condition.get("type", "")):
		"ROUTE_ENEMY":
			return report.route_fraction_enemy >= float(condition.get("threshold", 0.50))
		"HOLD_OBJECTIVE":
			var hex := _parse_hex(condition.get("hex_coord"))
			return int(_hold_player.get(hex, 0)) >= int(condition.get("hold_turns", 1))
		"SURVIVE_TURNS":
			return current_turn >= int(condition.get("target_turn", 1))
		"ELIMINATE_TARGET":
			return _squad_eliminated(String(condition.get("target_squad_id", "")))
		_:
			return false


## A tracked squad is "eliminated" when dead at HP 0 or routed off-map.
## Duel incapacitation (officer removed, squad alive) does NOT count.
func _squad_eliminated(key: String) -> bool:
	var squad: Squad = _vip_squads.get(key)
	if squad == null:
		return false  # authoring error: never triggers (GDD edge case)
	return squad.is_dead() or squad.is_off_map


func _ended(report: BattleResult, result: Result, trigger: String) -> BattleResult:
	report.result = result
	report.trigger_type = trigger
	return report


## Accepts {"q": int, "r": int} dictionaries or "q1r0s-1" strings.
func _parse_hex(value: Variant) -> Vector3i:
	if value is Dictionary:
		var q := int(value.get("q", 0))
		var r := int(value.get("r", 0))
		return Vector3i(q, r, -q - r)
	if value is String:
		var regex := RegEx.create_from_string("q(-?\\d+)r(-?\\d+)")
		var found := regex.search(value)
		if found != null:
			var q := int(found.get_string(1))
			var r := int(found.get_string(2))
			return Vector3i(q, r, -q - r)
	push_error("VictoryChecker: cannot parse objective hex '%s'" % str(value))
	return Vector3i.ZERO
