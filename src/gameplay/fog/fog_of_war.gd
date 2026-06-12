class_name FogOfWar
extends RefCounted
## Player-side fog of war: enemy squad visibility states and ghost tracking
## (design/gdd/fog-of-war.md).
##
## Terrain is always visible; fog governs ENEMY SQUAD POSITIONS only.
## VISIBLE requires range AND LOS from at least one friendly squad (union).
## Lost contact → PREVIOUSLY_SEEN ghost at the last known position (stale by
## design). The MVP AI has perfect information — fog is player-side only.

var _base_vision: Dictionary = { "INF": 2, "LI": 3, "CAV": 3, "ART": 2 }
var _staleness_threshold: int = 3
var grid: BattleGrid = null
var passives: PassiveRegistry = null


static func from_config(config: Dictionary, p_grid: BattleGrid, p_passives: PassiveRegistry = null) -> FogOfWar:
	var fog := FogOfWar.new()
	fog._base_vision = config.get("base_vision", fog._base_vision)
	fog._staleness_threshold = int(config.get("staleness_threshold", 3))
	fog.grid = p_grid
	fog.passives = p_passives
	return fog


## F-1: vision_range = base_vision[unit_class] + hill bonus + passive bonus.
func vision_range(squad: Squad) -> int:
	var base: int = int(_base_vision.get(squad.unit_class, 2))
	var terrain_mod := 0
	if grid != null and squad.tile != null:
		terrain_mod = grid.terrain.vision_modifier(squad.tile.type)
	return base + terrain_mod + squad.vision_bonus


## F-2: union visibility check — enemy E is visible if ANY friendly squad
## has it within vision_range AND unobstructed LOS. Boundary inclusive (<=).
func is_visible(enemy: Squad, friendly_squads: Array) -> bool:
	for friendly: Squad in friendly_squads:
		if not friendly.is_active():
			continue
		var d := CubeHex.distance(friendly.position, enemy.position)
		if d > vision_range(friendly):
			continue
		if grid == null or grid.has_line_of_sight(friendly.position, enemy.position):
			return true
	return false


## Recalculates visibility for all enemy squads (called at Movement Phase
## start and after every friendly move). Also refreshes Stratagem bonuses.
func recalculate(player_squads: Array, enemy_squads: Array, current_turn: int) -> void:
	if passives != null:
		var all_squads: Array = player_squads + enemy_squads
		var bonus := passives.vision_bonus_for_side(Squad.Side.PLAYER, all_squads)
		for squad: Squad in player_squads:
			squad.vision_bonus = bonus
	for enemy: Squad in enemy_squads:
		if not enemy.is_active():
			continue
		if is_visible(enemy, player_squads):
			enemy.visibility_state = Squad.Visibility.VISIBLE
			enemy.last_known_position = enemy.position
			enemy.last_known_unit_type = enemy.unit_type_id
			enemy.last_seen_turn = current_turn
		elif enemy.visibility_state == Squad.Visibility.VISIBLE:
			enemy.visibility_state = Squad.Visibility.PREVIOUSLY_SEEN
		# HIDDEN / PREVIOUSLY_SEEN stay as they are (ghost does not follow).


## Battle initialization: all enemies HIDDEN, then battle_start_reveals
## (Preparation Phase scouting) force-set listed squads VISIBLE at turn 0.
func initialize(player_squads: Array, enemy_squads: Array, battle_start_reveals: Array = []) -> void:
	for enemy: Squad in enemy_squads:
		enemy.visibility_state = Squad.Visibility.HIDDEN
		enemy.last_seen_turn = -1
	for enemy: Squad in enemy_squads:
		if battle_start_reveals.has(enemy.id):
			enemy.visibility_state = Squad.Visibility.VISIBLE
			enemy.last_known_position = enemy.position
			enemy.last_known_unit_type = enemy.unit_type_id
			enemy.last_seen_turn = 0
	# Initial vision pass only UPGRADES visibility (GDD init step 4):
	# pre-revealed squads stay VISIBLE for turn 1 even when out of range.
	if passives != null:
		var bonus := passives.vision_bonus_for_side(Squad.Side.PLAYER, player_squads + enemy_squads)
		for squad: Squad in player_squads:
			squad.vision_bonus = bonus
	for enemy: Squad in enemy_squads:
		if enemy.is_active() and is_visible(enemy, player_squads):
			enemy.visibility_state = Squad.Visibility.VISIBLE
			enemy.last_known_position = enemy.position
			enemy.last_known_unit_type = enemy.unit_type_id
			enemy.last_seen_turn = 1


## F-3: ghost staleness in turns; "?" badge at >= staleness_threshold.
func staleness_turns(enemy: Squad, current_turn: int) -> int:
	if enemy.last_seen_turn < 0:
		return 0
	return current_turn - enemy.last_seen_turn


func is_stale(enemy: Squad, current_turn: int) -> bool:
	return enemy.visibility_state == Squad.Visibility.PREVIOUSLY_SEEN \
		and staleness_turns(enemy, current_turn) >= _staleness_threshold


## Ranged attack constraint: only currently-VISIBLE enemies are targetable.
func can_target(enemy: Squad) -> bool:
	return enemy.visibility_state == Squad.Visibility.VISIBLE
