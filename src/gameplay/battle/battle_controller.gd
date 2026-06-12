class_name BattleController
extends RefCounted
## Tactical battle orchestrator: turn loop, player actions, a minimal enemy
## AI, and the per-round resolution pipeline.
##
## Round structure (morale-system.md §Turn Structure):
##   1. Player Movement+Combat phase (UI-driven)
##   2. Enemy Movement+Combat phase (AI — perfect information per fog GDD)
##   3. Morale Resolution → 4. Routing Resolution → 5. Recovery
##   6. Victory evaluation → next round
##
## NOTE: the enemy AI here is a deliberate placeholder — Tactical AI is an
## Alpha-tier system (#23). It advances toward the nearest player squad and
## attacks when legal. Replace when the Tactical AI GDD is designed.

signal log_event(message: String)
signal attack_resolved(attacker: Squad, defender: Squad, result: CombatResolver.AttackResult)
signal squad_removed(squad: Squad, reason: String)
signal battle_ended(report: VictoryChecker.BattleResult)

var grid: BattleGrid = null
var terrain: TerrainSystem = null
var resolver: CombatResolver = null
var morale: MoraleSystem = null
var fog: FogOfWar = null
var victory: VictoryChecker = null
var passives: PassiveRegistry = null
var duel_config: Dictionary = {}
var movement_config: Dictionary = {}
var rng: RandomNumberGenerator = null

## Every squad ever deployed (dead/off-map squads stay listed, inactive).
var squads: Array = []
var current_turn: int = 1
var battle_over: bool = false
var final_report: VictoryChecker.BattleResult = null
var battle_name: String = ""
## True while a duel overlay is active — tactical input frozen.
var duel_active: bool = false


## Loads a full battle from a BattleDefinition dictionary (see
## assets/data/battles/). All gameplay configs load from assets/data/.
static func load_battle(definition: Dictionary, p_rng: RandomNumberGenerator = null) -> BattleController:
	var controller := BattleController.new()
	controller.rng = p_rng if p_rng != null else RandomNumberGenerator.new()
	controller.battle_name = String(definition.get("display_name", definition.get("battle_id", "Battle")))

	controller.terrain = TerrainSystem.from_file()
	var season_name := String(definition.get("season", "dry")).to_upper()
	var season_index: int = TerrainSystem.Season.keys().find(season_name)
	var season: TerrainSystem.Season = (season_index if season_index != -1 else TerrainSystem.Season.DRY) as TerrainSystem.Season
	controller.grid = BattleGrid.from_map_rows(definition.get("map_rows", []), controller.terrain, season)

	var combat_config := ConfigLoader.load_json("res://assets/data/combat.json")
	var morale_config := ConfigLoader.load_json("res://assets/data/morale.json")
	controller.movement_config = ConfigLoader.load_json("res://assets/data/movement.json")
	controller.duel_config = ConfigLoader.load_json("res://assets/data/duel_config.json")
	var passive_config := ConfigLoader.load_json("res://assets/data/passive_config.json")
	var vision_config := ConfigLoader.load_json("res://assets/data/vision.json")

	controller.resolver = CombatResolver.from_config(combat_config, controller.terrain)
	controller.morale = MoraleSystem.from_config(morale_config)
	controller.passives = PassiveRegistry.from_config(passive_config, combat_config)
	controller.morale.passives = controller.passives
	controller.fog = FogOfWar.from_config(vision_config, controller.grid, controller.passives)

	var registry := OfficerRegistry.from_file()
	var enemy_officers: Dictionary = {}
	for entry: Dictionary in definition.get("enemy_officers", []):
		var officer := Officer.create(String(entry.get("id", "")), String(entry.get("name", "")), entry, true)
		enemy_officers[officer.id] = officer

	for entry: Dictionary in definition.get("player_squads", []):
		controller._spawn_squad(entry, Squad.Side.PLAYER, combat_config, morale_config, registry, enemy_officers)
	for entry: Dictionary in definition.get("enemy_squads", []):
		controller._spawn_squad(entry, Squad.Side.ENEMY, combat_config, morale_config, registry, enemy_officers)

	controller.passives.register_battle(controller.squads)

	controller.victory = VictoryChecker.from_definition(
		definition,
		controller.side_squads(Squad.Side.PLAYER).size(),
		controller.side_squads(Squad.Side.ENEMY).size()
	)
	for squad: Squad in controller.squads:
		if squad.officer != null:
			controller.victory.register_officer_squad(squad.officer.id, squad)
		controller.victory.register_officer_squad(squad.id, squad)

	# Default facing: toward the nearest enemy cluster (facing-and-flank.md).
	for squad: Squad in controller.squads:
		var foes: Array = []
		for other: Squad in controller.squads:
			if other.side != squad.side:
				foes.append(other.position)
		squad.facing_direction = FacingSystem.default_facing(squad.position, foes)

	for squad: Squad in controller.squads:
		squad.ap_pool = MovementRules.ap_pool(
			squad.unit_class,
			squad.officer.ldr() if squad.officer != null else 0,
			controller.movement_config
		)
		squad.begin_round()

	controller.fog.initialize(
		controller.side_squads(Squad.Side.PLAYER),
		controller.side_squads(Squad.Side.ENEMY),
		definition.get("battle_start_reveals", [])
	)
	return controller


func _spawn_squad(entry: Dictionary, side: Squad.Side, combat_config: Dictionary, morale_config: Dictionary, registry: OfficerRegistry, enemy_officers: Dictionary) -> void:
	var officer: Officer = null
	var officer_id: Variant = entry.get("officer")
	if officer_id != null and String(officer_id) != "":
		officer = registry.get_officer(String(officer_id))
		if officer == null:
			officer = enemy_officers.get(String(officer_id))
		if officer == null:
			push_error("BattleController: unknown officer '%s'" % String(officer_id))
	var squad := Squad.create(String(entry.get("id", "")), String(entry.get("unit_type", "")), combat_config, officer)
	if squad == null:
		return
	squad.side = side
	squad.init_morale(morale_config, int(entry.get("morale_override", -1)))
	var hex := CubeHex.offset_to_cube(int(entry.get("col", 0)), int(entry.get("row", 0)))
	grid.place_squad(squad, hex)
	squads.append(squad)


## Active squads of one side.
func side_squads(side: Squad.Side) -> Array:
	var result: Array = []
	for squad: Squad in squads:
		if squad.side == side and squad.is_active():
			result.append(squad)
	return result


# ------------------------------------------------------------------ player

## Reachable hexes (hex → AP cost) for a player squad this turn.
func reachable_for(squad: Squad) -> Dictionary:
	if battle_over or duel_active or squad.moved_this_turn \
			or squad.morale_state == Squad.MoraleState.BROKEN:
		return {}
	return grid.reachable_hexes(squad.position, squad.ap_remaining)


## Moves a squad along the least-cost path to [param destination].
## One move action per turn; facing updates per step; ford flag applied.
func move_squad(squad: Squad, destination: Vector3i) -> bool:
	if battle_over or duel_active or squad.moved_this_turn or not squad.is_active():
		return false
	if squad.morale_state == Squad.MoraleState.BROKEN:
		return false
	var path := grid.pathfind(squad.position, destination, squad.ap_remaining)
	if path.is_empty():
		return false
	_walk_path(squad, path)
	squad.moved_this_turn = true
	fog.recalculate(side_squads(Squad.Side.PLAYER), side_squads(Squad.Side.ENEMY), current_turn)
	return true


func _walk_path(squad: Squad, path: Array[Vector3i]) -> void:
	for hex in path:
		var dir := FacingSystem.facing_from_move(squad.position, hex)
		if dir != -1:
			squad.facing_direction = dir
		squad.ap_remaining -= grid.movement_cost(hex)
		var tile := grid.tile_at(hex)
		if tile != null and tile.type == TerrainSystem.TerrainType.FORD:
			squad.crossed_ford_this_turn = true
		grid.relocate_squad(squad, hex)


## Validates an attack order (range, LOS, fog, one attack per turn).
func can_attack(attacker: Squad, defender: Squad) -> bool:
	if battle_over or duel_active or attacker.attacked_this_turn:
		return false
	if not attacker.is_active() or not defender.is_active() or attacker.side == defender.side:
		return false
	if attacker.morale_state == Squad.MoraleState.BROKEN:
		return false
	var distance := CubeHex.distance(attacker.position, defender.position)
	if distance < attacker.range_min or distance > attacker.range_max:
		return false
	if attacker.attack_kind == Squad.AttackKind.RANGED:
		if not grid.has_line_of_sight(attacker.position, defender.position):
			return false
		if attacker.side == Squad.Side.PLAYER and not fog.can_target(defender):
			return false
	return true


## Executes an attack: flank classification (Facing & Flank + Shadow Work),
## hidden Heirloom Blade proc, damage resolution, kill handling.
func attack(attacker: Squad, defender: Squad) -> CombatResolver.AttackResult:
	if not can_attack(attacker, defender):
		return null
	var attacker_in_forest := attacker.tile != null and attacker.tile.type == TerrainSystem.TerrainType.FOREST
	var is_flanking := FacingSystem.is_flanking(attacker, defender, attacker_in_forest)
	if not is_flanking and passives.shadow_work_applies(attacker, attacker_in_forest):
		is_flanking = true
	var damage_override := passives.roll_blade_proc(attacker, rng)
	var result := resolver.resolve_attack(attacker, defender, is_flanking, damage_override)
	attacker.attacked_this_turn = true
	attacker.facing_direction = FacingSystem.facing_toward(attacker.position, defender.position)
	attack_resolved.emit(attacker, defender, result)
	if result.defender_killed:
		passives.on_kill(attacker, defender, squads)
		_remove_squad(defender, "killed")
	fog.recalculate(side_squads(Squad.Side.PLAYER), side_squads(Squad.Side.ENEMY), current_turn)
	return result


## Initiates a field duel challenge (duel-system.md Field Challenge rules).
## Returns a started DuelEngine, or null if the challenge is invalid.
func start_field_duel(challenger: Squad, target: Squad) -> DuelEngine:
	if battle_over or duel_active or challenger.challenge_used:
		return null
	if challenger.officer == null or target.officer == null:
		return null
	if CubeHex.distance(challenger.position, target.position) != 1:
		return null
	var engine := DuelEngine.from_config(duel_config)
	engine.start(challenger.officer, target.officer)
	challenger.challenge_used = true
	duel_active = true
	log_event.emit("%s challenges %s to a duel!" % [challenger.officer.display_name, target.officer.display_name])
	return engine


## Applies field duel outcome: loser officer incapacitated (squad becomes
## officer-less), −25 morale loser / +15 winner. Draw: no effects.
## Duel incapacitation does NOT trigger LOSE_VIP (GDD rule).
func finish_field_duel(engine: DuelEngine, challenger: Squad, target: Squad) -> void:
	duel_active = false
	var loser_delta := int(duel_config.get("field_duel_loser_morale_delta", -25))
	var winner_delta := int(duel_config.get("field_duel_winner_morale_delta", 15))
	var winner: Squad = null
	var loser: Squad = null
	match engine.outcome:
		DuelEngine.Outcome.VICTORY, DuelEngine.Outcome.YIELD:
			winner = challenger
			loser = target
		DuelEngine.Outcome.DEFEAT:
			winner = target
			loser = challenger
		_:
			log_event.emit("The duel ends in a draw — both officers withdraw.")
			return
	log_event.emit("%s defeats %s in the duel!" % [winner.officer.display_name, loser.officer.display_name])
	var loser_officer_id := loser.officer.id
	loser.lose_officer()
	loser.officer_lost_this_turn = false  # duel loss applies the flat delta instead
	passives.deregister_officer(loser_officer_id)
	loser.set_morale(loser.morale + loser_delta)
	winner.set_morale(winner.morale + winner_delta)


# ---------------------------------------------------------------- enemy AI

## Ends the player phase: runs the enemy AI, then the resolution pipeline.
func end_player_turn() -> void:
	if battle_over or duel_active:
		return
	_enemy_phase()
	_resolution_phase()


func _enemy_phase() -> void:
	for squad: Squad in side_squads(Squad.Side.ENEMY):
		if squad.morale_state == Squad.MoraleState.BROKEN:
			continue
		var target := _nearest_player_squad(squad)
		if target == null:
			return
		if not can_attack(squad, target):
			_ai_move_toward(squad, target)
		# Re-target after moving (nearest may have changed).
		target = _nearest_player_squad(squad)
		if target != null and can_attack(squad, target):
			attack(squad, target)
		if battle_over:
			return


func _nearest_player_squad(from_squad: Squad) -> Squad:
	var best: Squad = null
	var best_distance := 2147483647
	for squad: Squad in side_squads(Squad.Side.PLAYER):
		var d := CubeHex.distance(from_squad.position, squad.position)
		if d < best_distance:
			best_distance = d
			best = squad
	return best


func _ai_move_toward(squad: Squad, target: Squad) -> void:
	if squad.moved_this_turn:
		return
	var reachable := grid.reachable_hexes(squad.position, squad.ap_remaining)
	var best_hex := squad.position
	var best_score := _ai_hex_score(squad, squad.position, target)
	for hex: Vector3i in reachable.keys():
		var score := _ai_hex_score(squad, hex, target)
		if score < best_score:
			best_score = score
			best_hex = hex
	if best_hex == squad.position:
		return
	var path := grid.pathfind(squad.position, best_hex, squad.ap_remaining)
	if path.is_empty():
		return
	_walk_path(squad, path)
	squad.moved_this_turn = true


## Lower is better: ranged units want a legal firing hex; melee close in.
func _ai_hex_score(squad: Squad, hex: Vector3i, target: Squad) -> int:
	var d := CubeHex.distance(hex, target.position)
	if squad.attack_kind == Squad.AttackKind.RANGED:
		if d >= squad.range_min and d <= squad.range_max and grid.has_line_of_sight(hex, target.position):
			return 0
		return d + 10
	return d


# -------------------------------------------------------------- resolution

func _resolution_phase() -> void:
	var all_active: Array = side_squads(Squad.Side.PLAYER) + side_squads(Squad.Side.ENEMY)
	var events: Array = morale.resolve_morale_phase(all_active)
	for event in events:
		if event.newly_broken:
			log_event.emit("%s breaks and routs!" % event.squad.id)
	_routing_phase()
	morale.recovery_phase(side_squads(Squad.Side.PLAYER) + side_squads(Squad.Side.ENEMY))
	victory.update_objectives(squads)
	var report := victory.evaluate(squads, current_turn)
	if report.result != VictoryChecker.Result.ONGOING:
		battle_over = true
		final_report = report
		battle_ended.emit(report)
		return
	current_turn += 1
	for squad: Squad in squads:
		if squad.is_active():
			squad.begin_round()
	fog.recalculate(side_squads(Squad.Side.PLAYER), side_squads(Squad.Side.ENEMY), current_turn)


func _routing_phase() -> void:
	for squad: Squad in squads:
		if not squad.is_active() or squad.morale_state != Squad.MoraleState.BROKEN:
			continue
		if not squad.has_routing_target:
			squad.routing_target = grid.routing_target(squad.position)
			squad.has_routing_target = true
		if grid.is_edge_hex(squad.position):
			_rout_exit(squad)
			continue
		var path := grid.pathfind(squad.position, squad.routing_target, -1)
		if path.is_empty():
			squad.routing_blocked_turns += 1
			if squad.routing_blocked_turns >= int(movement_config.get("routing_timeout_turns", 3)):
				_rout_exit(squad)
			continue
		var budget := squad.ap_pool
		var walked: Array[Vector3i] = []
		for hex in path:
			var cost := grid.movement_cost(hex)
			if cost == TerrainSystem.IMPASSABLE or cost > budget:
				break
			budget -= cost
			walked.append(hex)
		if walked.is_empty():
			squad.routing_blocked_turns += 1
			if squad.routing_blocked_turns >= int(movement_config.get("routing_timeout_turns", 3)):
				_rout_exit(squad)
			continue
		squad.routing_blocked_turns = 0
		_walk_path(squad, walked)
		if grid.is_edge_hex(squad.position):
			_rout_exit(squad)


func _rout_exit(squad: Squad) -> void:
	squad.is_off_map = true
	grid.remove_squad(squad)
	victory.record_rout_exit(squad.side)
	squad_removed.emit(squad, "routed")
	log_event.emit("%s flees the field." % squad.id)


func _remove_squad(squad: Squad, reason: String) -> void:
	grid.remove_squad(squad)
	victory.record_death(squad.side)
	squad_removed.emit(squad, reason)
	log_event.emit("%s is destroyed." % squad.id)
